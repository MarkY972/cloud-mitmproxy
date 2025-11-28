from yoyo import step

steps = [
    step(
        """
        CREATE TABLE instances (
            id SERIAL PRIMARY KEY,
            task_arn VARCHAR(255) UNIQUE,
            status VARCHAR(255),
            public_ip VARCHAR(255)
        )
        """,
        "DROP TABLE instances",
    )
]
