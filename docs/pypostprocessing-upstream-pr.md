# Proposed PyPostProcessing upstream change (single PR)

Use this as a checklist when opening **one** pull request against [pyanodon/pypostprocessing](https://github.com/pyanodon/pypostprocessing). Review [open PRs](https://github.com/pyanodon/pypostprocessing/pulls) first to avoid duplication.

## 1. Angel’s + Py: allow AdminUnknownFixes instead of PyCoalTBaA

**File:** `prototypes/functions/compatibility.lua`

**Current (approx.):**

```lua
if mods["angelsrefining"] and not mods["PyCoalTBaA"] then
 error("\n\n\n\n\nPlease install PyCoal Touched By an Angel\n\n\n\n\n")
end
```

**Proposed:**

```lua
if mods["angelsrefining"] and not mods["PyCoalTBaA"] and not mods["AdminUnknownFixes"] then
 error("\n\n\n\n\nPlease install PyCoal Touched By an Angel\n\n\n\n\n")
end
```

**Rationale:** Legacy [PyCoalTBaA](https://mods.factorio.com/mod/PyCoalTBaA) is 1.1-era; the Angel’s + Py bridge content for Factorio 2.1 lives in [AdminUnknownFixes](https://github.com/jakegodding/AdminUnknownFixes). Players with AdminUnknownFixes should not need an empty `PyCoalTBaA` stub.

**Safety:** If the real `PyCoalTBaA` mod is enabled, `mods["PyCoalTBaA"]` is true and the error path is unchanged.

## 2. Changelog

Add an entry to PyPP `changelog.txt` per project style for the compatibility gate change.

## Suggested PR title

`Allow AdminUnknownFixes for Angel’s + Py compatibility gate`

## Suggested PR description (template)

- **Context:** AdminUnknownFixes merges former PyCoalTBaA bridge work for Factorio 2.1 + Angel’s + Py.
- **Change:** Skip the “install PyCoal Touched By an Angel” `error()` when `mods["AdminUnknownFixes"]` is set.
- **Links:** [AdminUnknownFixes repository](https://github.com/jakegodding/AdminUnknownFixes)
