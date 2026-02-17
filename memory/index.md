---
id: mem-index
title: Cheney Memory Index
type: index
tags: [memory, index, cheney]
created: 2026-02-16
updated: 2026-02-16
scope: cheney
status: active
---

# Cheney Memory Index

Purpose: durable, agent-friendly context graph for resumable work.

## Active Notes

- Project: [[proj-rb1-fedora-env-baseline]]
- Decision: [[dec-rag-phase1-lexical-first]]

## Collections

- Inbox: `memory/inbox/`
- Projects: `memory/projects/`
- Entities: `memory/entities/`
- Rules: `memory/rules/`
- Decisions: `memory/decisions/`
- Templates: `memory/templates/`

## Retrieval Quickstart

1. List notes: `rg --files memory`
2. Find by id/tag: `rg -n "^id:|^tags:" memory`
3. Find links/backlinks: `rg -n "\[\[(.+)\]\]" memory`
