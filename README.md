# MyQuotes - Flutter 

Flutter client application for a data-driven literary system, designed to consume structured data via RPC and SQL-backed backend services.

This project represents the **client layer** of the MyQuotes ecosystem, focusing on browsing, searching, and navigating normalized literary data derived from processed Kindle highlights.

---

## 🖼️ Application Previews

<table>
  <tr>
    <td align="center">
      <b>Home Screen</b><br><br>
      <img src="https://github.com/user-attachments/assets/1ecd082d-4654-485b-a105-54652af0cb15" width="250">
    </td>
    <td align="center">
      <b>Search and Filters</b><br><br>
      <img src="https://github.com/user-attachments/assets/b7a222c2-129f-46dd-b1bc-3f00ba5def07" width="250">
    </td>
    <td align="center">
      <b>Quote Details</b><br><br>
      <img src="https://github.com/user-attachments/assets/3c246acf-a805-41c5-bc71-9029579c2ea4" width="250">
    </td>
  </tr>
</table>


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

