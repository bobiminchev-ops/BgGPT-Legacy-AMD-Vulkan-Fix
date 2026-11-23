# BgGPT on Legacy AMD Radeon — Vulkan Fix

[Български](#български) | [English](#english)

---

## Български

### Какъв е проблемът?
При опит за локално стартиране на българския езиков модел **BgGPT** на INSAIT (`BgGPT-Gemma-3-4B-IT-Q6_K.gguf`) през **Vulkan** на по-стари видеокарти на AMD от архитектура GCN 2.0 (като **AMD Radeon R9 390 8 GB**, последни официални драйвери Adrenalin 22.6.1 и липса на ROCm поддръжка), моделът работи коректно на процесора (CPU), но при GPU ускорение генерира безсмислен текст, повтарящи се символи или йероглифи.

Причините са две:
1. **Липса на хардуерен FP16 (полуточност):** По подразбиране Vulkan бекендът използва 16-битови сметки с плаваща запетая, което при старите GCN чипове води до математическо препълване (`NaN`).
2. **Несъвместимост на Vulkan Flash Attention с Gemma 3:** Редуването на локално (*sliding window*) и глобално внимание в архитектурата Gemma 3 задейства шейдър път в Vulkan Flash Attention (64-нишкови вълни), който връща счупени стойности при старите AMD драйвери дори при изключен FP16.

### Решението
Комбинация от две променливи на средата за Vulkan и изключване на Flash Attention при стартиране на `llama-server.exe`:

- `set "GGML_VK_DISABLE_F16=1"` — принуждава Vulkan да изчислява в 32-битова точност (FP32) вместо в проблемния FP16 режим.
- `set "GGML_VK_DISABLE_ASYNC=1"` — изключва асинхронното подаване на Vulkan задачи, което създава нестабилност при старите драйвери.
- `-fa off` (или `-fa 0` при по-стари билдове) — изключва Flash Attention.
- `-ngl 99` — зарежда всички слоеве на модела във видеопаметта (8 GB VRAM).

### Реални резултати от теста
- **Видеокарта:** AMD Radeon R9 390 8 GB (GCN 2.0 / Hawaii)
- **Драйвер:** AMD Radeon Software Adrenalin 22.6.1 (Windows)
- **Сървър:** `llama.cpp` Vulkan x64 за Windows (билд `llama-b12651-bin-win-vulkan-x64`)
- **Модел:** `BgGPT-Gemma-3-4B-IT-Q6_K.gguf` (INSAIT)
- **Скорост и качество:** Стабилни, граматически правилни отговори на български език със скорост **~30 токена/секунда** и **0 €** разход за нов хардуер.

### Какво трябва да изтеглите сами
Този проект съдържа **само** стартовия скрипт (`Start-BgGPT-R9-390.bat`) и документацията. Поради размера и лицензите им, трябва да изтеглите отделно:
1. **Сървъра (`llama.cpp` за Windows с Vulkan):** Изтеглете архива `llama-b...-bin-win-vulkan-x64.zip` от официалните издания на [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp/releases) и го разархивирайте в избрана папка.
2. **Модела (`BgGPT-Gemma-3-4B-IT-Q6_K.gguf`):** Изтеглете GGUF файла от официалния профил на [INSAIT-Institute в Hugging Face](https://huggingface.co/INSAIT-Institute) и го поставете в **същата папка**, където се намира `llama-server.exe`.

### Бърз старт
1. Копирайте файла **`Start-BgGPT-R9-390.bat`** в папката при `llama-server.exe` и `BgGPT-Gemma-3-4B-IT-Q6_K.gguf`.
2. Стартирайте **`Start-BgGPT-R9-390.bat`** с двойно щракване.
3. Изчакайте в конзолата да се зареди моделът и отворете в браузъра адрес **`http://127.0.0.1:8080`** (или свържете локален клиент като **AnythingLLM** към OpenAI-съвместимия адрес `http://127.0.0.1:8080/v1`).

### Полезни бележки
- **По-голям контекст за работа с документи (RAG / AnythingLLM):** По подразбиране скриптът задава `-c 2048`. При 4B модел и 8 GB VRAM можете спокойно да редактирате `.bat` файла и да увеличите контекста на `-c 4096` или `-c 8192`.
- **По-стара версия на `llama.cpp`:** Ако вашата версия на `llama-server.exe` не разпознава `-fa off`, заменете го с `-fa 0`.
- **Ограничение на гаранцията:** Решението е доказано с практически тест на **Radeon R9 390 8 GB**. Вероятно ще помогне и при други стари AMD карти (R9 290/390, RX 470/480/570/580), но работата на всеки конкретен хардуер не може да бъде гарантирана на 100%.

### Автор и принос
- **Автор:** Boris G. Minchev (2026)
- **Диагностика и тестване:** Постигнато чрез съвместно емпирично тестване и отстраняване на грешки с **ChatGPT** и **Gemini**.

---

## English

### The Problem
When running INSAIT's Bulgarian language model **BgGPT** (`BgGPT-Gemma-3-4B-IT-Q6_K.gguf`) locally via **Vulkan** on legacy AMD GCN 2.0 GPUs (such as the **AMD Radeon R9 390 8 GB**, capped at Adrenalin 22.6.1 drivers without ROCm support), inference works properly on the CPU but outputs garbled text, repeated tokens, or gibberish when offloaded to the GPU.

Two underlying issues cause this behavior:
1. **Lack of Native FP16 Hardware Support:** By default, the Vulkan backend uses 16-bit floating-point math, triggering `NaN` overflows on legacy GCN drivers.
2. **Vulkan Flash Attention Incompatibility with Gemma 3:** Gemma 3's alternating sliding-window and global attention layers trigger a Vulkan Flash Attention shader path (subgroup size 64) that produces corrupted outputs on legacy AMD drivers even when FP16 is disabled.

### The Fix
Combine two Vulkan environment variables with disabled Flash Attention when launching `llama-server.exe`:

- `set "GGML_VK_DISABLE_F16=1"` — forces FP32 compute in Vulkan instead of broken FP16.
- `set "GGML_VK_DISABLE_ASYNC=1"` — disables asynchronous Vulkan command submission that causes instability on older drivers.
- `-fa off` (or `-fa 0` on older builds) — disables Flash Attention.
- `-ngl 99` — offloads all model layers into the 8 GB VRAM.

### Verified Benchmark Results
- **GPU:** AMD Radeon R9 390 8 GB (GCN 2.0 / Hawaii)
- **Driver:** AMD Radeon Software Adrenalin 22.6.1 (Windows)
- **Runtime:** `llama.cpp` Windows Vulkan x64 build (`llama-b12651-bin-win-vulkan-x64`)
- **Model:** `BgGPT-Gemma-3-4B-IT-Q6_K.gguf` (INSAIT)
- **Performance:** Coherent, accurate Bulgarian responses at **~30 tokens/second** with **€0** spent on replacement hardware.

### Prerequisites
This repository contains **only** the startup script (`Start-BgGPT-R9-390.bat`) and documentation. Download the runtime and model weights separately from their official sources:
1. **`llama.cpp` Windows Vulkan x64 binary:** Download `llama-b...-bin-win-vulkan-x64.zip` from [ggml-org/llama.cpp releases](https://github.com/ggml-org/llama.cpp/releases) and extract it to a folder.
2. **BgGPT GGUF Model (`BgGPT-Gemma-3-4B-IT-Q6_K.gguf`):** Download the GGUF file from [INSAIT-Institute on Hugging Face](https://huggingface.co/INSAIT-Institute) and place it in the **same folder** as `llama-server.exe`.

### Quick Start
1. Place **`Start-BgGPT-R9-390.bat`** in the folder containing `llama-server.exe` and `BgGPT-Gemma-3-4B-IT-Q6_K.gguf`.
2. Double-click **`Start-BgGPT-R9-390.bat`**.
3. Wait for the model to finish loading, then open **`http://127.0.0.1:8080`** in your browser (or connect a local RAG client such as **AnythingLLM** to `http://127.0.0.1:8080/v1`).

### Notes & Troubleshooting
- **Larger Context for Document RAG (AnythingLLM):** The default script uses `-c 2048`. With a 4B quantized model on 8 GB VRAM, you can edit the `.bat` file to `-c 4096` or `-c 8192` for longer document chunks.
- **Older `llama.cpp` Builds:** If your `llama-server.exe` build does not recognize `-fa off`, replace it with `-fa 0`.
- **Disclaimer:** Empirically verified on an **AMD Radeon R9 390 8 GB**. While these flags may also resolve garbled Vulkan output on other legacy AMD GPUs (R9 290/390, RX 470/480/570/580), compatibility across every card cannot be guaranteed.

### Author & Credits
- **Author:** Boris G. Minchev (2026)
- **Testing & Diagnostics:** Achieved through iterative empirical testing and cross-AI debugging collaboration with **ChatGPT** and **Gemini**.
