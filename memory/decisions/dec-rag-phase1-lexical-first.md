---
id: dec-rag-phase1-lexical-first
title: RAG Strategy Phase 1 Uses Markdown + Lexical Retrieval
type: decision
tags: [decision, rag, memory, retrieval]
created: 2026-02-16
updated: 2026-02-16
scope: cheney
status: accepted
---

# RAG Strategy Phase 1 Uses Markdown + Lexical Retrieval

## Question

Should we build a vector database-backed RAG system now, or first ship a markdown-graph memory layer with lexical retrieval?

## Options Considered

1. Build vector DB now (higher immediate complexity, stronger semantic recall).
2. Start with markdown graph + lexical retrieval (`rg`, metadata, links), then add vector DB later.
3. Skip structured memory and rely on ad hoc logs only.

## Decision

Choose option 2 for phase 1. Implement the markdown memory graph now and defer vector DB until data volume and retrieval friction justify it.

## Consequences

1. Faster setup and lower operational risk in early homelab phases.
2. Every note remains human-readable and git-auditable.
3. Semantic retrieval remains a known gap until phase 2.

## Trigger To Revisit

Revisit vector DB addition when any two conditions are true:

1. Total memory notes exceed 300 files.
2. Lexical search misses relevant context in three or more sessions per week.
3. Cross-note semantic lookup is required for autonomous task handoff quality.

## Candidate Phase-2 Additions

1. Build embeddings index for `memory/**/*.md`.
2. Store embeddings in a local DB (for example Qdrant/SQLite+FAISS).
3. Keep lexical retrieval as fallback and combine results (hybrid retrieval).

## Links

- Index: [[mem-index]]
- Project: [[proj-rb1-fedora-env-baseline]]
