#!/bin/bash

# Verify all endpoints use correct /api prefix
echo "Checking for incorrect endpoint usage in Flutter code..."
echo ""

echo "1. Checking for hardcoded /pages without /api:"
grep -r "'/pages" lib/ --include="*.dart" || echo "   ✓ No hardcoded /pages paths found"

echo ""
echo "2. Checking for hardcoded /canvases without /api:"
grep -r "'/canvases" lib/ --include="*.dart" || echo "   ✓ No hardcoded /canvases paths found"

echo ""
echo "3. Checking for hardcoded /comments without /api:"
grep -r "'/comments" lib/ --include="*.dart" || echo "   ✓ No hardcoded /comments paths found"

echo ""
echo "4. Checking for hardcoded /auth without /api:"
grep -r "'/auth" lib/ --include="*.dart" || echo "   ✓ No hardcoded /auth paths found"

echo ""
echo "5. Checking ApiEndpoints usage:"
grep -r "ApiEndpoints\." lib/core/services/ --include="*.dart" | wc -l
echo "   service files using ApiEndpoints"

echo ""
echo "6. Verifying endpoints.dart has /api prefix:"
grep "apiVersion = '/api'" lib/core/api/endpoints.dart && echo "   ✓ API version correctly set to /api"

echo ""
echo "✅ Verification complete!"
