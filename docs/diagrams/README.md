# Diagrams

A diagram earns its file when it shows a mechanism prose struggles with: a flow between
components, a state machine, a dependency order between cards, a migration path.

- **File name** `<adr-id>-<diagram-name>.mmd`, for example `0001-request-flow.mmd`.
  Mermaid first. PlantUML, `.puml`, only when mermaid cannot draw it.
- **A flow is a sequence diagram.** Participants are the components the ADR names; the
  messages are the calls; `alt` and `else` carry the other paths (a refusal, a 304, a
  failure); `loop` carries a walk. Flowcharts, class or state diagrams only when the
  idea is not a flow: a structure, a migration between two shapes, a state machine.
- **Notes are the point.** A `Note over` carries what the reader would otherwise open a
  file for: the HTTP request line, the response headers, the map that crosses the
  call, the schema name, a one-line snippet. A sequence diagram without notes is a
  list of arrows.
- **Detail is a dial.** More detail brings the diagram closer to the code (the function
  names, the exact maps); less detail is the design at a glance. An ADR's diagram sits
  where its section needs it: the problem at a glance, the solution close to the code.
- **One diagram per file, one idea per diagram.** A second idea is a second file.
- **The ADR embeds the diagram:** the file's relative path on one line, then a
  ```` ```mermaid ```` block that is a copy of the file, since GitHub renders the block
  and not the file. The file is the source; a change is made in the file and copied.
- **Mermaid text:** a semicolon inside a message or a note is written `#59;`, since
  mermaid reads a bare one as a line break; `<br/>` breaks a line inside a note. A
  mermaid statement is one line and does not wrap, like a table row.
- **Render.** GitHub renders mermaid inside markdown. For a `.mmd` file use an editor
  preview or `mmdc -i <file>.mmd -o <file>.svg` (mermaid-cli). For PlantUML,
  `plantuml <file>.puml`.
