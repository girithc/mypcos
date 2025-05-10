import os
from typing import Union
from openai import OpenAI
import json

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def call_openai(prompt: str, return_type: str = "text") -> Union[str, dict]:
    response = client.chat.completions.create(
        model="gpt-4.1-nano",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
    )
    result = response.choices[0].message.content.strip()
    print("result from OpenAI:", result)

    if return_type == "json":
        try:
            json_start = result.find("{")
            json_end = result.rfind("}") + 1
            cleaned = result[json_start:json_end]
            return json.loads(cleaned)
        except json.JSONDecodeError as e:
            print("⚠️ JSON parsing failed")
            print(result)
            raise

    return result
