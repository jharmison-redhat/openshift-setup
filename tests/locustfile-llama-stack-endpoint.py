import json
import os
import random
import time

from locust import HttpUser, TaskSet, between, task


customers = [
    "Acme Corp",
    "Globex Inc",
    "Soylent Corp",
]

questions = [
    "Review the current opportunities",
    "Get a list of support cases",
    "Determine the status of the account, e.g. unhappy, happy etc. based on the cases",
    "Send a slack message to agentic-ai-slack with the status of the account",
]

class LlamaStackInteraction(TaskSet):
    def on_start(self):
        with self.client.get("/models") as response:
            try:
                self.model = random.choice([model["identifier"] for model in response.json()["data"] if model["model_type"] == "llm"])
            except json.JSONDecodeError:
                response.failure("Response could not be decoded as JSON")
            except KeyError:
                response.failure("Response did not contain expected keys to identify model")
        agent_config = {
            "model": self.model,
            "instructions": "You are a helpful AI assistant, responsible for helping me find and communicate information back to my team. You have access to a number of tools. Whenever a tool is called, be sure return the Response in a friendly and helpful tone. When you are asked to find out about opportunities and support cases you must use a tool. If you need to create a pdf you must use a tool, create the content for the pdf as simple markdown formatted as tables where possible and add this markdown to the start of the generated markdown:  '![ParasolCloud Logo](https://i.postimg.cc/MHZB5tmL/Screenshot-2025-04-21-at-5-58-46-PM.png) *Secure Cloud Solutions for a Brighter Business* \n --- \n'  ",
            "tool_config": {"tool_choice": "auto"},
            "toolgroups": ["mcp::crm", "mcp::pdf", "mcp::slack", "mcp::upload"],
            "sampling_params": {"strategy": {"type": "greedy"}, "max_tokens": os.getenv("MAX_TOKENS", 128000)},
        }
        with self.client.post("/agents", json={"agent_config": agent_config}) as response:
            try:
                self.agent = response.json()["agent_id"]
            except json.JSONDecodeError:
                response.failure("Response could not be decoded as JSON")
            except KeyError:
                response.failure("Response did not contain expected keys to identify agent")
        with self.client.post(f"/agents/{self.agent}/session", json={"session_name": self.agent}) as response:
            try:
                self.session = response.json()["session_id"]
            except json.JSONDecodeError:
                response.failure("Response could not be decoded as JSON")
            except KeyError:
                response.failure("Response did not contain expected keys to identify session")

    def on_stop(self):
        self.client.delete(f"/agents/{self.agent}/sessions/{self.session}")
        self.client.delete(f"/agents/{self.agent}")

    @task
    def discuss_customer(self):
        customer = random.choice(customers)
        for question in questions:
            message = f"{question} for {customer}"
            with self.client.post(
                f'/agents/{self.agent}/session/{self.session}/turn',
                json={
                    "stream": True,
                    "messages": [
                        {
                            "role": "user",
                            "content": message,
                        },
                    ],
                },
                stream=True,
            ) as response:
                for chunk in response.iter_content(chunk_size=None, decode_unicode=True):
                    try:
                        data = json.loads(chunk.lstrip("data: "))
                        if data['event']['payload']['event_type'] == "turn_complete":
                            print("turn complete")
                    except:
                        pass

            time.sleep(1)
        self.interrupt()


class LlamaStackUser(HttpUser):
    host = os.getenv("LLAMA_STACK_BASE_URI", 'http://llamastack-server-llama-serve.apps.cluster.demo.jharmison.dev/v1')
    wait_time = between(1, 5)
    tasks = [LlamaStackInteraction]
