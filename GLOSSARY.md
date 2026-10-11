# AI editing

AI editing sends source context and editing requests to an interactive tool.

## Language

**Reference**: A source file path, optionally followed by a line or line range.
_Avoid_: Source snippet

**Scoped fix**: An interactive editing request with a Reference, a Source snippet and the user's message.
_Avoid_: LLM exec

**Source snippet**: Source text supplied as context for a Scoped fix.
_Avoid_: Reference
