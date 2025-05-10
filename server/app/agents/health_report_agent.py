import json
from app.utils.extract_text import extract_text_from_file
from app.services.openai_services import call_openai


class HealthReportAgent:
    """
    Agent responsible for analyzing uploaded health reports, extracting medical data, and generating 
    health advice using LLMs. Optionally integrates with a RAG pipeline for contextual responses.

    Attributes:
        rag_chain (Callable): Optional function to query the RAG system with a message.
    """

    def __init__(self, rag_chain=None):
        """
        Initializes the HealthReportAgent with an optional RAG chain function.

        Args:
            rag_chain (Callable, optional): A function that accepts a query string and returns
                a tuple of (response, source_documents). Defaults to None.
        """
        self.rag_chain = rag_chain

    def parse_report(self, file_path: str) -> str:
        """
        Extracts raw text from a given PDF or document file.

        Args:
            file_path (str): Local path to the uploaded health report.

        Returns:
            str: Extracted plain text from the file.
        """
        return extract_text_from_file(file_path)

    def estimate_tokens(self, text: str) -> int:
        """
        Roughly estimates the number of tokens in a given string. 
        (Assumes 1 token ≈ 4 characters, per OpenAI guidance.)

        Args:
            text (str): Text content.

        Returns:
            int: Estimated token count.
        """
        return len(text) // 4

    def extract_medical_info(self, report_text: str) -> dict:
        """
    Uses GPT to extract structured health values and findings from report text.
    - report_values: every lab analyte name + its exact value (and units) as written.
    - medical_findings: each interpreted finding, with detail & reason.

    Args:
        report_text (str): Cleaned text content from the report.

    Returns:
        dict: {
            "report_values": { "<Test Name>": "<value>", … },
            "medical_findings": {
                "<Finding summary>": {
                    "detail": "<explanation>",
                    "reason": "<which value(s) support it>"
                }, …
            }
        }
    """
        prompt = f"""
        You are a medical assistant. Extract two things from the following lab report:

1) report_values: a dictionary mapping *every* analyte or test name exactly as it appears (including any parentheses/units) to its value (including units).  Do NOT omit any – capture all lines of the form “Name: value” or “Name (units): value”.

2) medical_findings: a dictionary where each key is a short finding summary, and each value is an object with:
   - detail: the clinical meaning,
   - reason: exactly which report_values drove that conclusion.

Output ONLY valid JSON, no commentary.  Follow this schema:

        {{
        "report_values": {{
            "<Test Name 1>": "<value1>",
            "<Test Name 2>": "<value2>",
            …
        }},
        "medical_findings": {{
            "<Finding summary 1>": {{
            "detail": "<detailed explanation>",
            "reason": "<specific value(s) supporting this>"
            }},
            "<Finding summary 2>": {{
            "detail": "<detailed explanation>",
            "reason": "<specific value(s) supporting this>"
            }},
            …
        }}
        }}

        Here’s the report:
        {report_text}
        """
        return call_openai(prompt, return_type="json")
        
    def generate_health_plan(self, health_data: dict) -> str:
        """
        Generates health guidance (exercise, diet, supplements) based on extracted medical data.

        Args:
            health_data (dict): Structured health data from `extract_medical_info`.

        Returns:
            str: Natural language health advice for the user.
        """
        prompt = f"""
        You are a PCOS health coach. Based on the following medical data, generate:
        1. Exercise recommendation
        2. Diet plan
        3. Supplement, medicine and doctor suggestions

        Medical Data:
        {json.dumps(health_data, indent=2)}

        Be friendly and helpful.
        """
        return call_openai(prompt)

    def run(self, file_path: str):
        """
        End-to-end pipeline to analyze a health report:
            1. Extract text from the uploaded file
            2. Estimate token count
            3. Extract structured medical info via LLM
            4. Generate user-facing advice via RAG (if enabled)

        Args:
            file_path (str): Path to the uploaded report.

        Returns:
            dict: {
                "json_data": extracted structured health values,
                "gpt_response": health guidance from the assistant,
                "docs": RAG source documents (if any),
                OR
                "error": failure reason
            }
        """
        report_text = self.parse_report(file_path)
        approx_tokens = self.estimate_tokens(report_text)
        print(f"🧠 Approximate tokens in report: {approx_tokens}")

        try:
            medical_data = self.extract_medical_info(report_text)

            message = f"""
Here is some extracted medical data:

{json.dumps(medical_data, indent=2)}

Can you please suggest:
1. An exercise routine,
2. A diet plan, and
3. Supplement/medicine recommendations?

Respond with warmth and clarity.
            """.strip()

            response, source_docs = self.rag_chain(message, mode="upload")

            sources = []
            seen = set()
            for doc in source_docs:
                snippet = doc.page_content[:300].strip()
                meta = doc.metadata
                key = (meta.get("source"), meta.get("page"))
                if key not in seen:
                    seen.add(key)
                    sources.append({
                        "page": str(meta.get("page", "N/A")),
                        "title": meta.get("title", "Online article" if meta.get("source") == "DuckDuckGo" else "Untitled"),
                        "source": meta.get("source", "Unknown"),
                        "snippet": snippet
                    })

            return {
                "json_data": medical_data,
                "gpt_response": response,
                "docs": sources
            }

        except Exception as e:
            return {
                "error": "Failed to process report.",
                "details": str(e)
            }
