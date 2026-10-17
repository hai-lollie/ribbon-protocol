# Diagrams

A diagram earns its file when it shows a mechanism prose struggles with: a flow between
components, a state machine, a dependency order between cards.

- **File name** `<adr-id>-<diagram-name>.mmd`, for example `0001-request-flow.mmd`.
  Mermaid first. PlantUML, `.puml`, only when mermaid cannot draw it.
- **One diagram per file, one idea per diagram.** A second idea is a second file.
- The ADR links its diagram on its `Diagram:` line. A short mermaid block may also sit
  inline in the ADR, since GitHub renders it there; when both exist, the file is the
  source.
- **Render.** GitHub renders mermaid inside markdown. For a `.mmd` file use an editor
  preview or `mmdc -i <file>.mmd -o <file>.svg` (mermaid-cli). For PlantUML,
  `plantuml <file>.puml`.
