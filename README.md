# MyQuotes (Flutter)

Flutter client application for a data-driven literary system, designed to consume structured data via RPC and SQL-backed backend services.

This project represents the **client layer** of the MyQuotes ecosystem, focusing on browsing, searching, and navigating normalized literary data derived from processed Kindle highlights.

---

## Overview

The application provides a clean and efficient interface for interacting with structured datasets produced by a backend data pipeline.  
It emphasizes clarity, performance, and maintainable UI flows driven by well-defined data models.

The backend system (implemented separately) is responsible for data ingestion, ETL workflows, normalization, and persistence, while this Flutter client focuses exclusively on data consumption and presentation.

---

## Key Features

- Search and filtering over structured literary datasets
- Navigation by books, authors, characters, and quotes
- Data-driven UI powered by normalized backend models
- Clear separation between client and backend responsibilities
- Emphasis on maintainability and readability

---

## Architecture

- **Client:** Flutter
- **Communication:** RPC / API-based integration
- **Data Source:** SQL-backed backend services
- **Design Approach:** Client-server separation with data-centric UI flows

The application is intentionally designed as a thin client, delegating data processing and business logic to the backend layer.

---

## Related Project

- **MyQuotes (Flask Backend):**  
  Backend service responsible for data ingestion, ETL, modeling, and storage of Kindle highlights.

---

## Getting Started

```bash
flutter pub get
flutter run
```

## Notes

Environment-specific configuration files (e.g., secrets or API endpoints) are intentionally excluded from version control and should be provided locally when running the application.

## Author

Developed by Márcio Martins
Data Engineer | Big Data Analyst | Technical Documentation Specialist

