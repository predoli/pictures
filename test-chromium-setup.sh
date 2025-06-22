#!/bin/bash

# Test script for Chromium Photo Frame setup
# Verifies that the conversion from Tauri to Chromium was successful

echo "=== Testing Chromium Photo Frame Setup ==="

# Check if frontend builds successfully
echo "1. Testing frontend build..."
cd frontend
if npm install && npm run build; then
    echo "✅ Frontend builds successfully"
else
    echo "❌ Frontend build failed"
    exit 1
fi

# Check if dist directory was created
if [ -d "dist" ]; then
    echo "✅ Frontend dist directory created"
    echo "   Files: $(ls -la dist/)"
else
    echo "❌ Frontend dist directory not found"
    exit 1
fi

# Check if index.html exists and doesn't have Tauri references
if [ -f "dist/index.html" ]; then
    echo "✅ index.html exists"
    
    if grep -q "tauri" dist/index.html; then
        echo "⚠️  Warning: Found Tauri references in index.html"
    else
        echo "✅ No Tauri references found in index.html"
    fi
else
    echo "❌ index.html not found in dist"
    exit 1
fi

# Check if assets were built
if [ -d "dist/assets" ]; then
    echo "✅ Assets directory exists"
    echo "   Asset files: $(ls dist/assets/ | wc -l) files"
else
    echo "❌ Assets directory not found"
    exit 1
fi

# Test if we can serve the frontend locally
echo ""
echo "2. Testing local serving..."
cd ..

# Start backend in background for testing
echo "Starting test backend..."
cd backend
go run . &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 3

# Test if backend is responding
if curl -s "http://localhost:8080/images?count=1&ordering=date_asc" >/dev/null; then
    echo "✅ Backend is responding"
else
    echo "❌ Backend not responding"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# Test if frontend can be served (basic check)
cd frontend/dist
if python3 -m http.server 8081 >/dev/null 2>&1 &
then
    FRONTEND_PID=$!
    sleep 2
    
    if curl -s "http://localhost:8081" >/dev/null; then
        echo "✅ Frontend can be served"
        kill $FRONTEND_PID 2>/dev/null
    else
        echo "❌ Frontend serving failed"
        kill $FRONTEND_PID 2>/dev/null
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
fi

# Cleanup
kill $BACKEND_PID 2>/dev/null
echo ""
echo "✅ All tests passed! Chromium setup is ready."
echo ""
echo "Next steps:"
echo "1. Build the project: cd frontend && npm run build"
echo "2. Test with Chromium: chromium-browser --kiosk file://$(pwd)/frontend/dist/index.html"
echo "3. Make sure backend is running on localhost:8080"