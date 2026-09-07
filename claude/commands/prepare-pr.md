Look at my last PRs (use `gh pr list --author @me`) to find the proper language for commit messages and PR descriptions. If the repo has a `.github/pull_request_template.md`, read it for the required sections.

Then show me:

1. A commit message
2. A PR title and description (using the template structure if one exists)

Rules:
- Don't list files changed or test plans
- For "description":
  - If you can put it in a short paragraph or two, go for it. Otherwise, consider an "**Issue:**", "**Cause:**", "**Solution:**" structure. The goal is that people don't get a gigantic/boring description, but once they read it they understand the problem and solution without needing to read the code.
  - Don't over-reference the code in the description; it's ok to mention a file or function name if it's important for understanding the issue or solution, but otherwise avoid it.
- Don't create the PR or commit yet, just show the descriptions
- Don't co-sign either the commit or PR
- Don't create a PR unless explicitly told to do so
- For UI tasks, choose the appropriate visual documentation (if in doubt, ask me):
  - **Before/after screenshots**: Best for simple visual changes (styling, layout). Use a markdown table with two images side by side ("before|after" header, "-|-" separator, images on third line).
  - **Animated GIF**: Best for UI state transitions (button changes, filters applied/cleared, toggles). Create using this workflow:
    1. Take screenshots at each state (e.g., initial → interaction → result → reset)
    2. Create optimized GIF: `magick -delay 80 frame1.png frame2.png frame3.png -delay 120 final.png -loop 0 -layers OptimizeFrame -colors 128 output.gif`
    3. Include the GIF in the PR description (typical result: ~20KB vs ~1MB for full screenshots)
  - **Screencast**: For complex multi-step interactions or animations that need smooth video. Remind me to record one manually if needed.
  - Use placeholders if you can't upload images to the host and LMK once you create the PR so I amend the description.
  - You can crop to focus on the relevant area with `magick <input>.png -crop WIDTHxHEIGHT+X+Y +repage <output>.png`; ensure you don't lose context. Don't delete the pre-crop images until I've had the opportunity to review the cropped versions, in case I ask for adjustments.
