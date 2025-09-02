import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()  # reads .env
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def chat_with_gpt(prompt: str) -> str:
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}]
    )
    return resp.choices[0].message.content.strip()

if __name__ == "__main__":
    print("Chatbot started. Type 'quit' to exit.")
    while True:
        user_input = input("You: ").strip()
        if user_input.lower() in {"quit", "exit", "bye"}:
            print("Chatbot: Bye!")
            break
        try:
            answer = chat_with_gpt(user_input)
            print("Chatbot:", answer)
        except Exception as e:
            print("Error:", e)
