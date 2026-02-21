#!/usr/bin/env node
import fs from "node:fs";

const MARKER = "CHENEY_TUI_LIVE_BLURB_V1";

function fail(message) {
	console.error(message);
	process.exit(1);
}

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) fail("Usage: openclaw_tui_live_blurb_transform.mjs <input.js> <output.js>");

let source = fs.readFileSync(inputPath, "utf8");
let changed = false;

if (!source.includes(MARKER)) {
	const setToken = "const setActivityStatus = (text) => {";
	const footerFnToken = "const updateFooter = () => {";
	const setStart = source.indexOf(setToken);
	if (setStart < 0) fail("Patch anchor not found: setActivityStatus");
	const footerFnStart = source.indexOf(footerFnToken, setStart);
	if (footerFnStart < 0) fail("Patch anchor not found: updateFooter");
	const setLineStart = source.lastIndexOf("\n", setStart) + 1;
	const setIndent = source.slice(setLineStart, setStart);
	const activityReplacement = `${setIndent}const setActivityStatus = (text) => {
${setIndent}\tactivityStatus = text;
${setIndent}\trenderStatus();
${setIndent}\tupdateFooter();
${setIndent}};
${setIndent}const inferFooterTier = (provider, model, thinking) => {
${setIndent}\tconst p = String(provider ?? "").toLowerCase();
${setIndent}\tconst m = String(model ?? "").toLowerCase();
${setIndent}\tconst t = String(thinking ?? "off").toLowerCase();
${setIndent}\tif (!p && !m) return null;
${setIndent}\tif (p.includes("ollama")) return "local";
${setIndent}\tif (p.includes("openai") || m.includes("gpt-5")) {
${setIndent}\t\tif (t === "high") return "high";
${setIndent}\t\tif (t === "medium") return "normal";
${setIndent}\t\tif (t === "low") return "low";
${setIndent}\t\treturn "cloud";
${setIndent}\t}
${setIndent}\treturn p || "remote";
${setIndent}};
${setIndent}/* ${MARKER} */
`;
	source = source.slice(0, setLineStart) + activityReplacement + source.slice(footerFnStart);
	const footerPartsToken = "const footerParts = [";
	const footerPartsStart = source.indexOf(footerPartsToken, footerFnStart);
	if (footerPartsStart < 0) fail("Patch anchor not found: footerParts");
	const footerLineStart = source.lastIndexOf("\n", footerPartsStart) + 1;
	const footerIndent = source.slice(footerLineStart, footerPartsStart);
	const footerPartsEndToken = "].filter(Boolean);";
	const footerPartsEnd = source.indexOf(footerPartsEndToken, footerPartsStart);
	if (footerPartsEnd < 0) fail("Patch anchor not found: footerParts end");
	const footerBlockEnd = footerPartsEnd + footerPartsEndToken.length;
	const footerReplacement = `${footerIndent}const tier = inferFooterTier(sessionInfo.modelProvider, sessionInfo.model, think);
${footerIndent}const footerParts = [
${footerIndent}\t\`agent \${agentLabel}\`,
${footerIndent}\t\`session \${sessionLabel}\`,
${footerIndent}\t\`action \${activityStatus}\`,
${footerIndent}\tmodelLabel,
${footerIndent}\ttier ? \`tier \${tier}\` : null,
${footerIndent}\tthink !== "off" ? \`think \${think}\` : null,
${footerIndent}\tverbose !== "off" ? \`verbose \${verbose}\` : null,
${footerIndent}\treasoningLabel,
${footerIndent}\ttokens
${footerIndent}].filter(Boolean);`;
	source = source.slice(0, footerLineStart) + footerReplacement + source.slice(footerBlockEnd);
	changed = true;
}

if (!source.includes(MARKER)) fail("Patch marker missing after transform");
fs.writeFileSync(outputPath, source);
console.log(JSON.stringify({ inputPath, outputPath, changed, marker: MARKER }));
