# Thndr DevOps Task

In this exercise, you will build a **FastAPI** application with two main APIs for **depositing** and **withdrawing** money. You’ll also demonstrate your DevOps skills by **containerizing** and **deploying** your application on **Kubernetes** using **Helm**. We expect you to spend around 1 working day on this assignment.

## Getting Started

This exercise requires [Python](https://www.python.org/) to be installed. The instructions assume you’re using **Poetry** to manage dependencies, but feel free to use any alternative. If you don’t have **Poetry** installed, follow the instructions [here](https://python-poetry.org/docs/#installation).

1. **Create a repository** for this folder.

2. **Install dependencies**:

   ```bash
   poetry install
   ```

3. **Export the `PYTHONPATH`** (to ensure the local modules are discoverable by Python):

   ```bash
   export PYTHONPATH=.
   ```

4. **Apply migrations** (if you add any):

   ```bash
   poetry run alembic upgrade head
   ```

5. **Seed the database** (if you decide to add seed data):

   ```bash
   poetry run python app/seed.py
   ```

6. **Run the server**:

   ```bash
   poetry run fastapi dev app/main.py
   ```

   By default, it should start on `localhost:8000`.

❗️ **Make sure all changes are committed to the main branch!**

## Technical Details

- The database is **SQLite**, and the ORM is [SQLAlchemy](https://www.sqlalchemy.org/). [Alembic](https://alembic.sqlalchemy.org/) is used for migrations.
- The existing schema can be found in `app/models.py`.
- User authentication is handled using the `get_current_user` dependency in `app/dependencies/get_current_user.py`, via `user_id` in the request header.
- You only need to implement **deposit** and **withdraw** endpoints for this exercise.

## APIs To Implement

1. **_POST_** `/deposit`
   - Deposits money into the user’s balance.
   - Should handle fractional amounts correctly.

2. **_POST_** `/withdraw`
   - Withdraws money from the user’s balance.
   - Must ensure the user has enough balance.
   - Should handle fractional amounts correctly.

## Deployment Using Kubernetes & Helm

As part of this assignment, you should:

1. **Containerize** the application.
2. Write a **Helm chart** to deploy the containerized application to a Kubernetes cluster.
3. **Logging & Monitoring**: Integrate a logging and monitoring solution (e.g., Prometheus, Grafana) to track application and cluster metrics.

## Additional Requirements

- **CI/CD Pipeline**: Show how you might integrate with a pipeline (GitHub Actions, Jenkins, etc.) to build, test, and deploy the container automatically.
- **Service Mesh Integration**: Integrate a service mesh (e.g., Istio or Linkerd) to handle mTLS for secure communication between microservices, implement traffic routing rules for canary deployments, and improve observability (metrics and distributed tracing) across your application.
- **Security**: Provide brief notes on how you’d secure this setup (e.g., secrets management in Kubernetes, scanning Docker images for vulnerabilities).

## Submitting the Assignment

When you finish:

1. **Zip** your repository (include the `.git` folder).
2. Send us the zip file.
3. Include a **notes file** (`NOTES.md` or similar) with any additional explanations, decisions, or instructions.

**Important:** Do not share the repo publicly on GitHub or elsewhere.

Feel free to use LLMs as long as you fully understand and endorse the choices it’s making and the code it’s writing.

**Good luck!** 🍀
