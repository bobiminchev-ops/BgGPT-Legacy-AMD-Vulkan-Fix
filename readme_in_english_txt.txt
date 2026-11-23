================================================================================
BgGPT on Legacy AMD Radeon — Vulkan Fix
(Running INSAIT's BgGPT on Legacy AMD Radeon GPUs via Vulkan)
================================================================================

PROJECT OVERVIEW
----------------
This repository provides a ready-to-use startup script and configuration for 
running the Bulgarian large language model BgGPT (developed by INSAIT) on 
legacy AMD Radeon GCN 2.0 (Hawaii) GPUs, such as the Radeon R9 390 8 GB, under 
Windows using the Vulkan backend of llama.cpp.

THE PROBLEM
-----------
When running BgGPT (based on the Gemma 3 architecture) with default llama.cpp 
settings on an AMD Radeon R9 390 (using the final official Adrenalin 22.6.1 
drivers):
- On the CPU, the model generates accurate Bulgarian text, but very slowly.
- On the GPU (via Vulkan), the model outputs garbled symbols, repetitions, or 
  nonsensical text.

This behavior is caused by three limitations of legacy GCN 2.0 hardware and 
drivers:
1. Lack of native hardware FP16 support, leading to numerical overflows (NaN) 
   during half-precision calculations.
2. Incompatibility between Vulkan Scalar Flash Attention in Gemma 3 models 
   (which alternate local sliding-window and global attention) and the 64-wide 
   wavefronts on older AMD shader compilers.
3. Instability in asynchronous Vulkan command submission (Async) on legacy 
   drivers.

THE WORKING SOLUTION
--------------------
Combining the following environment variables and llama-server.exe flags 
completely resolves the output corruption:

- set "GGML_VK_DISABLE_F16=1"   -> Forces Vulkan to compute in 32-bit precision 
                                   (FP32), eliminating NaN overflows.
- set "GGML_VK_DISABLE_ASYNC=1" -> Disables unstable asynchronous submission 
                                   in the legacy Vulkan driver.
- -fa off                       -> Disables Flash Attention (the decisive fix 
                                   for coherent Gemma 3 Bulgarian output).
- -ngl 99                       -> Offloads all model layers into the GPU's 
                                   8 GB VRAM.
- -c 2048                       -> Sets the context window size (can be raised 
                                   to 4096 or 8192 for document RAG workflows 
                                   in AnythingLLM).

BENCHMARK & TEST RESULTS
------------------------
- GPU: AMD Radeon R9 390 (8 GB VRAM, GCN 2.0)
- Driver: AMD Adrenalin 22.6.1 (Windows 10/11 x64)
- Runtime: llama.cpp (build llama-b12651-bin-win-vulkan-x64)
- Model: BgGPT-Gemma-3-4B-IT-Q6_K.gguf (INSAIT)
- Generation Speed: ~30 tokens/second (clean, coherent Bulgarian output)
- Additional Hardware Cost: €0

HOW TO USE (STEP-BY-STEP)
-------------------------
The Start-BgGPT-R9-390.bat script does not bundle the llama.cpp binaries or the 
model weights; it automates the required runtime configuration. To launch the 
local server:

1. Download the Windows Vulkan release of llama.cpp from the official GitHub 
   releases page (https://github.com/ggml-org/llama.cpp/releases) — look for 
   llama-bXXXXX-bin-win-vulkan-x64.zip and extract it into a folder.
2. Download the BgGPT-Gemma-3-4B-IT-Q6_K.gguf model file from INSAIT's official 
   Hugging Face repository (https://huggingface.co/INSAIT-Institute).
3. Place BgGPT-Gemma-3-4B-IT-Q6_K.gguf and Start-BgGPT-R9-390.bat into the 
   same folder as llama-server.exe.
4. Double-click Start-BgGPT-R9-390.bat to start the server.
5. Once the model finishes loading into VRAM, open your browser and navigate 
   to: http://127.0.0.1:8080

CONNECTING TO ANYTHINGLLM (LOCAL DOCUMENT LIBRARY)
--------------------------------------------------
1. Keep the Start-BgGPT-R9-390.bat server window running in the background.
2. In AnythingLLM settings, select LLM Provider: Generic OpenAI.
3. Set Base URL to: http://127.0.0.1:8080/v1
4. Enter any placeholder API Key (e.g., not-needed) and Model Name: BgGPT.

AUTHORSHIP & ACKNOWLEDGMENTS
----------------------------
Author: Boris G. Minchev (2026)
License: MIT License

This fix was discovered, tested, and verified through collaborative debugging 
with ChatGPT and Google Gemini.