#!/bin/bash

# Test script to verify Chromium can access local files and load images
# This tests the solution to the CORS/file access issue

echo "=== Testing Chromium Local File Access ==="

# Build frontend first
echo "1. Building frontend..."
cd frontend
if ! npm install >/dev/null 2>&1; then
    echo "❌ npm install failed"
    exit 1
fi

if ! npm run build >/dev/null 2>&1; then
    echo "❌ Frontend build failed"
    exit 1
fi

echo "✅ Frontend built successfully"

# Check if Chromium is available
echo ""
echo "2. Checking Chromium availability..."
CHROMIUM_BIN=""
for bin in chromium-browser chromium google-chrome chrome; do
    if command -v "$bin" >/dev/null 2>&1; then
        CHROMIUM_BIN="$bin"
        echo "✅ Found Chromium: $CHROMIUM_BIN"
        break
    fi
done

if [ -z "$CHROMIUM_BIN" ]; then
    echo "❌ Chromium not found. Install with: sudo apt install chromium-browser"
    exit 1
fi

# Create a simple test HTML file to verify file access
echo ""
echo "3. Creating test file for file access verification..."
cat > dist/test-file-access.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>File Access Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #333; color: white; }
        .result { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .success { background: #4CAF50; }
        .error { background: #f44336; }
        .warning { background: #ff9800; }
    </style>
</head>
<body>
    <h1>Chromium File Access Test</h1>
    <div id="results"></div>
    
    <script>
        const results = document.getElementById('results');
        
        function addResult(message, type = 'success') {
            const div = document.createElement('div');
            div.className = `result ${type}`;
            div.innerHTML = message;
            results.appendChild(div);
        }
        
        // Test 1: Can we make HTTP requests?
        addResult('Testing HTTP request capability...', 'warning');
        
        fetch('http://localhost:8080/images?count=1&ordering=date_asc')
            .then(response => {
                if (response.ok) {
                    addResult('✅ HTTP requests to localhost:8080 work!', 'success');
                    return response.json();
                } else {
                    addResult(`⚠️ Backend responded with status: ${response.status}`, 'warning');
                    return null;
                }
            })
            .then(data => {
                if (data && data.images && data.images.length > 0) {
                    addResult(`✅ Backend returned ${data.images.length} images`, 'success');
                    
                    // Test image loading
                    const firstImage = data.images[0];
                    const imageUrl = `http://localhost:8080${firstImage.url}`;
                    addResult(`Testing image load: ${firstImage.filename}`, 'warning');
                    
                    const img = new Image();
                    img.onload = () => {
                        addResult('✅ Image loading works!', 'success');
                        addResult('🎉 All tests passed! Photo frame should work.', 'success');
                    };
                    img.onerror = () => {
                        addResult('❌ Image loading failed', 'error');
                        addResult('Check backend static file serving', 'error');
                    };
                    img.src = imageUrl;
                } else {
                    addResult('ℹ️ No images found in backend response', 'warning');
                }
            })
            .catch(error => {
                addResult(`❌ HTTP request failed: ${error.message}`, 'error');
                addResult('Make sure backend is running on localhost:8080', 'error');
            });
        
        // Test 2: Display current configuration
        addResult(`User Agent: ${navigator.userAgent}`, 'warning');
        addResult(`Current URL: ${window.location.href}`, 'warning');
    </script>
</body>
</html>
EOF

echo "✅ Test file created"

# Start backend for testing
echo ""
echo "4. Starting backend for testing..."
cd ../backend
if [ -f "main.go" ]; then
    go run . &
    BACKEND_PID=$!
    echo "✅ Backend started (PID: $BACKEND_PID)"
    
    # Wait for backend to start
    sleep 3
    
    # Test if backend is responding
    if curl -s "http://localhost:8080/images?count=1&ordering=date_asc" >/dev/null; then
        echo "✅ Backend is responding"
    else
        echo "⚠️ Backend not responding yet, but continuing test..."
    fi
else
    echo "⚠️ Backend not found, continuing without it"
    BACKEND_PID=""
fi

cd ../frontend

# Test Chromium with file access flags
echo ""
echo "5. Testing Chromium with file access flags..."
TEST_FILE="file://$(pwd)/dist/test-file-access.html"

echo "Opening test file: $TEST_FILE"
echo ""
echo "Chromium will open with the test page."
echo "Look for green ✅ messages indicating success."
echo "Red ❌ messages indicate issues that need fixing."
echo ""
echo "Press Ctrl+C to stop the test when done viewing."

# Launch Chromium with the necessary flags
"$CHROMIUM_BIN" \
    --allow-file-access-from-files \
    --allow-file-access \
    --allow-cross-origin-auth-prompt \
    --disable-web-security \
    --disable-features=VizDisplayCompositor \
    --user-data-dir="/tmp/chromium-test-$(date +%s)" \
    "$TEST_FILE" &

CHROMIUM_PID=$!

# Wait for user to finish testing
echo "Chromium started (PID: $CHROMIUM_PID)"
echo "Close the Chromium window or press Ctrl+C when done testing."

# Wait for Chromium to close or user interrupt
wait $CHROMIUM_PID 2>/dev/null

# Cleanup
if [ -n "$BACKEND_PID" ]; then
    echo "Stopping backend..."
    kill $BACKEND_PID 2>/dev/null
fi

echo ""
echo "Test completed!"
echo ""
echo "If you saw green ✅ messages, the photo frame should work correctly."
echo "If you saw red ❌ messages, check the backend configuration."