import os
import random

from locust import HttpUser, TaskSet, task


messages = [
    "Hello!",
    "What's the maximum flight speed of the African swallow?",
    "Tell me everything you know about Red Hat, the software company.",
    "Is Kubeflow a well adopted open source project?",
    "What's up, doc?"
]

class LanguageModelInteraction(TaskSet):
    def on_start(self):
        self.client.headers = {'Authorization': f'Bearer {os.getenv("TOKEN", "fake")}'}
        with self.client.get("/models") as response:
            try:
                self.model = response.json().get("data")[0].get("id")
            except JSONDecodeError:
                response.failure("Response could not be decoded as JSON")
            except KeyError:
                response.failure("Response did not contain expected keys to identify model")
            except IndexError:
                response.failure("No models appear to be loaded on the server")

    @task
    def list_models(self):
        self.client.get("/models")

    @task(5)
    def make_query(self):
        self.client.post(
            '/chat/completions',
            json={
                "model": self.model,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a helpful assistant.",
                    },
                    {
                        "role": "user",
                        "content": random.choice(messages),
                    },
                ],
            },
        )

class LanguageModelUser(HttpUser):
    host = os.getenv("BASE_URI", 'https://llama-32-3b-model-serving.apps.cluster.demo.jharmison.dev/v1')
    tasks = [LanguageModelInteraction]
