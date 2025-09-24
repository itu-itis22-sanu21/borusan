@echo off
REM Change to the directory of this script
cd /d "%~dp0"

REM Launch the chatbot with lower-cost defaults
python chatbot.py --model gpt-4o-mini --max-tokens 128 --temperature 0.3 --system "You are a helpful assistant."

REM Keep the window open after exitt
pause
