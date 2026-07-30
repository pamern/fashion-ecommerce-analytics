from pathlib import Path

import kagglehub


def main() -> None:
    output_dir = Path("data/raw")
    output_dir.mkdir(parents=True, exist_ok=True)

    path = kagglehub.competition_download(
        "datathon-2026-round-1",
        output_dir=str(output_dir),
    )

    print(f"Competition files downloaded to: {path}")


if __name__ == "__main__":
    main()