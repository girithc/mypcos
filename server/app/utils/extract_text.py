import fitz  # PyMuPDF
import tiktoken

def count_tokens(text: str, model: str = "gpt-4.1-nano") -> int:
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))


def extract_text_from_file(file_path: str) -> str:
    text = ""
    with fitz.open(file_path) as doc:
        for page in doc:
            text += page.get_text()
    return text.strip()
