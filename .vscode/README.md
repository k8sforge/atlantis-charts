# VS Code Configuration

## Helm Template Files

Helm template files in `templates/` contain Go templating syntax (`{{ }}`) which isn't valid YAML. The configuration treats these files as `plaintext` to disable YAML validation.

### If You Still See YAML Validation Errors:

1. **Reload VS Code Window**:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Developer: Reload Window"
   - Press Enter

2. **Close and Reopen Template Files**:
   - Close all template files
   - Reopen them

3. **Verify File Association**:
   - Open a template file (e.g., `templates/ingress.yaml`)
   - Check the language mode in the bottom-right corner of VS Code
   - It should show "Plain Text" not "YAML"

4. **Manual Language Selection** (if needed):
   - Open a template file
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Change Language Mode"
   - Select "Plain Text"

### Configuration Details:

- **File Associations**: All `templates/*.yaml` files are associated with `plaintext`
- **Schema Exclusion**: Templates are excluded from Kubernetes schema validation
- **YAML Lint**: `.yamllint` is configured to ignore the `templates/` directory

**Note**: The YAML validation errors are false positives and won't affect Helm functionality. Helm validates these files correctly when you run `helm lint` or `helm template`.

## Extensions

Recommended extensions are listed in `extensions.json`. The Kubernetes Tools extension provides better Helm template support.
