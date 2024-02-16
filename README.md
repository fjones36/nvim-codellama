# nvim-codellama

This repo is meant to provide step-by-step instructions for configuring neovim
to use llama.cpp as a local version of copilot.

It is based off of this blog post from Gierdo: https://gierdo.astounding.technology/blog/2023/11/24/llama-vim
and his fork of neoai.nvim.

## Installation

### Step 1: Clone Llama.cpp

`git clone https://github.com/ggerganov/llama.cpp.git`


### Step 2: Container
Build the llama.cpp container using the provided Dockerfile.

```
cp full-cuda-openai.Dockerfile llama.cpp/.devops/
cd llama.cpp/
docker build -t local/llama.cpp:full-cuda-openai -f .devops/full-cuda-openai.Dockerfile .
```


### Step 3: Neovim Packer Configuration

```
function check_llama_cpp()
    local output = vim.fn.system("docker ps -a")
    local lines = vim.split(output, "\n")
    for _, line in ipairs(lines) do
        if line:find("llama_cpp") then
            return "llama_cpp"
        end
    end
    vim.fn.system(
    "docker run -d --name llama_cpp -p 8000:8000 --rm --gpus all -v /home/fjones/repos/models:/app/models local/llama.cpp:full-cuda-openai python3 -m llama_cpp.server --model /app/models/codellama-7b-instruct.Q4_K_M.gguf --host 0.0.0.0")
    return "llama_cpp"
end
```

```
-- CodeLLAMA Support
use({
    "gierdo/neoai.nvim",
    branch = 'local-llama',
    requires = { "MunifTanjim/nui.nvim" },
    cmd = {
        "NeoAI",
        "NeoAIOpen",
        "NeoAIClose",
        "NeoAIToggle",
        "NeoAIContext",
        "NeoAIContextOpen",
        "NeoAIContextClose",
        "NeoAIInject",
        "NeoAIInjectCode",
        "NeoAIInjectContext",
        "NeoAIInjectContextCode",
    },
    config = function()
        check_llama_cpp()
        require("neoai").setup({
            -- Options go here
            ui = {
                output_popup_text = "NeoAI",
                input_popup_text = "--Prompt",
                width = 30,               -- As percentage eg. 30%
                output_popup_height = 80, -- As percentage eg. 80%
                submit = "<Enter>",       -- Key binding to submit the prompt
            },
            models = {
                {
                    name = "openai",
                    model = "codellama",
                    params = nil,
                },
            },
            register_output = {
                ["g"] = function(output)
                    return output
                end,
                ["c"] = require("neoai.utils").extract_code_snippets,
            },
            inject = {
                cutoff_width = 75,
            },
            prompts = {
                default_prompt = function()
                    return "Please only follow instructions or answer to questions. Be concise."
                end,
                context_prompt = function(context)
                    return "Please only follow instructions or answer to questions. Be concise. "
                        .. "I'd like to provide some context for future "
                        .. "messages. Here is the code/text that I want to refer "
                        .. "to in our upcoming conversations:\n\n"
                        .. context
                end,
            },
            mappings = {
                ["select_up"] = "<C-k>",
                ["select_down"] = "<C-j>",
            },
            open_ai = {
                url = "http://localhost:8000/v1/chat/completions",
                display_name = "llama.cpp",
                api_key = {
                    env = "OPENAI_API_KEY",
                    value = "12345",
                },
            },
            shortcuts = {
                -- {
                --     name = "textify",
                --     key = "<leader>as",
                --     desc = "fix text with AI",
                --     use_context = true,
                --     prompt = [[
                --         Please rewrite the text to make it more readable, clear,
                --         concise, and fix any grammatical, punctuation, or spelling
                --         errors
                --     ]],
                --     modes = { "v" },
                --     strip_function = nil,
                -- },
                -- {
                --     name = "gitcommit",
                --     key = "<leader>ag",
                --     desc = "generate git commit message",
                --     use_context = false,
                --     prompt = function()
                --         return [[
                --             Using the following git diff generate a consise and
                --             clear git commit message, with a short title summary
                --             that is 75 characters or less:
                --         ]] .. vim.fn.system("git diff --cached")
                --     end,
                --     modes = { "n" },
                --     strip_function = nil,
                -- },
            },

        })
    end,
})
```

Run `:PackerSync` and restart neovim.

