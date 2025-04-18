local M = {}

local dap = require "dap"

function M.evaluate_expr(session, expr, frameId, callback)
  session:request("evaluate", { expression = expr, context = "hover", frameId = frameId }, callback)
end

function M.fallback_evaluate(session, expr, callback)
  session:request("threads", {}, function(err, threads_response)
    if err then
      print("Error getting threads: " .. (err.message or "unknown error"))
      return
    end
    if threads_response and threads_response.threads and #threads_response.threads > 0 then
      local threadId = threads_response.threads[1].id
      session:request("stackTrace", { threadId = threadId, startFrame = 0, levels = 1 }, function(err, stack_response)
        if err then
          print("Error getting stack trace: " .. (err.message or "unknown error"))
          return
        end
        if stack_response and stack_response.stackFrames and #stack_response.stackFrames > 0 then
          local newFrameId = stack_response.stackFrames[1].id
          print("Fallback: got frame id " .. newFrameId)
          M.evaluate_expr(session, expr, newFrameId, callback)
        else
          print "No stack frames available"
        end
      end)
    else
      print "No threads available"
    end
  end)
end

function M.copy_variable_value()
  print "copy_variable_value triggered"

  local expr = vim.fn.expand "<cword>"
  print("Variable under cursor: " .. expr)
  if expr == "" then
    print "No variable found under cursor"
    return
  end

  local session = dap.session()
  if not session then
    print "No active debug session"
    return
  else
    print "Active debug session found"
  end

  -- Use JSON serialization so that the output is a valid JSON string.
  local wrapped_expr = string.format('__import__("json").dumps(%s, default=str, ensure_ascii=False)', expr)
  print("Evaluating: " .. wrapped_expr)

  local function handle_evaluation(err, response)
    if err then
      print("Error evaluating variable: " .. (err.message or "unknown error"))
      return
    end
    if not response or not response.result then
      print("No result returned for variable: " .. expr)
      return
    end

    local result = response.result
    print("Raw evaluation result: " .. result)

    -- Write the JSON string into a new scratch buffer.
    vim.cmd "enew"
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false

    -- Save to a file on the desktop.
    local temp_file = "D:\\OneDrive\\Desktop\\variable_value.txt"
    local file = io.open(temp_file, "w")
    file:write(result)
    file:close()

    -- Call the internal program: json-to-dict
    local command = 'json-to-dict -i "D:\\OneDrive\\Desktop\\variable_value.txt" -o "D:\\OneDrive\\Desktop\\temp.txt"'
    local success = os.execute(command)
    if success then
      print "json-to-dict command executed successfully"
    else
      print "Failed to execute json-to-dict command"
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { result })
    vim.cmd "setlocal filetype=json"
  end

  local frameId = vim.g.current_frame_id
  if frameId then
    M.evaluate_expr(session, wrapped_expr, frameId, function(err, response)
      if err then
        print("Error evaluating with stored frame id: " .. (err.message or "unknown error"))
        M.fallback_evaluate(session, wrapped_expr, handle_evaluation)
      else
        handle_evaluation(err, response)
      end
    end)
  else
    print "No frame id stored; trying fallback evaluation"
    M.fallback_evaluate(session, wrapped_expr, handle_evaluation)
  end
end

function M.format_python_or_json()
  -- Get the start and end lines of the visual selection.
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local text = table.concat(lines, "\n")

  -- Locate the first balanced literal enclosed in {}.
  local literal_start, literal_end = text:find "(%b{})"
  if not literal_start then
    print "Could not extract a literal (dict or JSON) from selection"
    return
  end

  local literal = text:sub(literal_start, literal_end)
  local prefix = text:sub(1, literal_start - 1)
  local suffix = text:sub(literal_end + 1)

  -- Try formatting as JSON first.
  local formatted = vim.fn.system("python -m json.tool", literal)
  if vim.v.shell_error ~= 0 then
    -- Fall back to formatting as a Python dict.
    formatted = vim.fn.system(
      'python -c "import ast, pprint, sys; d = ast.literal_eval(sys.stdin.read()); pprint.pprint(d)"',
      literal
    )
    if vim.v.shell_error ~= 0 then
      print "Error formatting input. Is Python installed and is the literal valid?"
      return
    end
  end

  local formatted_lines = vim.split(formatted, "\n", { trimempty = true })
  if #formatted_lines == 0 then return end

  local new_text_lines = {}

  if prefix:match "%S" then
    -- CASE 1: There is a non-whitespace prefix (e.g. a variable assignment).
    local prefix_lines = vim.split(prefix, "\n", { trimempty = false })
    local assignment_line = prefix_lines[#prefix_lines] or ""
    assignment_line = assignment_line:gsub("%s+$", "") -- trim trailing whitespace

    local rest_pre = {}
    if #prefix_lines > 1 then
      for i = 1, #prefix_lines - 1 do
        table.insert(rest_pre, prefix_lines[i])
      end
    end

    -- Set indent based on the assignment line's length.
    local indent = string.rep(" ", #assignment_line + 1)

    -- Add any prefix lines except the assignment.
    for _, l in ipairs(rest_pre) do
      table.insert(new_text_lines, l)
    end

    -- Join the assignment and the first line of the formatted literal.
    local first_line = assignment_line .. " " .. formatted_lines[1]
    table.insert(new_text_lines, first_line)

    -- Append the remaining formatted lines, indented.
    for i = 2, #formatted_lines do
      table.insert(new_text_lines, indent .. formatted_lines[i])
    end
  else
    -- CASE 2: No non-whitespace prefix; preserve the original left indentation.
    local original_indent = text:match "^(%s*)" or ""
    for _, line in ipairs(formatted_lines) do
      table.insert(new_text_lines, original_indent .. line)
    end
  end

  -- Append any suffix (if present) to the last line.
  if suffix and suffix:match "%S" then
    local suffix_trimmed = suffix:gsub("^%s+", "")
    new_text_lines[#new_text_lines] = new_text_lines[#new_text_lines] .. " " .. suffix_trimmed
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_text_lines)
end

-- Map the unified formatter to <leader>p in visual mode.
format_python_or_json = M.format_python_or_json

function M.setup()
  vim.keymap.set("n", "<F8>", M.copy_variable_value, { silent = false, desc = "Copy variable value to new buffer" })
  vim.api.nvim_set_keymap("v", "<leader>p", ":lua format_python_or_json()<CR>", { noremap = true, silent = true })
end

return M
