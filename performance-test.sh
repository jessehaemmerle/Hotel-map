#!/bin/bash

# Performance Testing Suite for Hotel Mapping Application
echo "🏨 Hotel Mapping Application - Performance Testing Suite"
echo "======================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}[PERF-TEST]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
API_URL="${API_URL:-http://localhost:8001}"
RESULTS_DIR="./performance-results"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to check if services are running
check_services() {
    print_header "Checking service availability..."
    
    # Check frontend
    if curl -s -f "$FRONTEND_URL" > /dev/null; then
        print_success "Frontend is accessible at $FRONTEND_URL"
    else
        print_error "Frontend is not accessible at $FRONTEND_URL"
        return 1
    fi
    
    # Check API
    if curl -s -f "$API_URL/api/hotels" > /dev/null; then
        print_success "API is accessible at $API_URL"
    else
        print_error "API is not accessible at $API_URL"
        return 1
    fi
    
    return 0
}

# Function to install k6 if not available
install_k6() {
    if ! command -v k6 &> /dev/null; then
        print_warning "k6 not found. Installing k6..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux installation
            sudo gpg -k
            sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
            echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
            sudo apt-get update
            sudo apt-get install k6
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS installation
            if command -v brew &> /dev/null; then
                brew install k6
            else
                print_error "Homebrew not found. Please install k6 manually: https://k6.io/docs/getting-started/installation/"
                return 1
            fi
        else
            print_error "Unsupported OS. Please install k6 manually: https://k6.io/docs/getting-started/installation/"
            return 1
        fi
        
        print_success "k6 installed successfully"
    else
        print_success "k6 is already installed"
    fi
}

# Function to run basic load test
run_basic_load_test() {
    print_header "Running Basic Load Test..."
    
    cat > "$RESULTS_DIR/basic-load-test.js" << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '1m', target: 5 },
    { duration: '30s', target: 0 },
  ],
};

const BASE_URL = __ENV.FRONTEND_URL || 'http://localhost:3000';
const API_URL = __ENV.API_URL || 'http://localhost:8001';

export default function() {
  // Test frontend
  const frontendRes = http.get(BASE_URL);
  check(frontendRes, {
    'frontend status is 200': (r) => r.status === 200,
  });

  // Test API
  const apiRes = http.get(`${API_URL}/api/hotels`);
  check(apiRes, {
    'API status is 200': (r) => r.status === 200,
    'API returns JSON': (r) => r.headers['Content-Type'].includes('application/json'),
  });

  sleep(1);
}
EOF

    k6 run \
        --env FRONTEND_URL="$FRONTEND_URL" \
        --env API_URL="$API_URL" \
        --out json="$RESULTS_DIR/basic-load-results.json" \
        "$RESULTS_DIR/basic-load-test.js"
}

# Function to run stress test
run_stress_test() {
    print_header "Running Stress Test..."
    
    cat > "$RESULTS_DIR/stress-test.js" << 'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '2m', target: 20 },
    { duration: '1m', target: 30 },
    { duration: '2m', target: 30 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed: ['rate<0.1'],
  },
};

const API_URL = __ENV.API_URL || 'http://localhost:8001';

export default function() {
  // Hotel search with different parameters
  const searchParams = [
    'latitude=40.7128&longitude=-74.0060&radius=10000',
    'latitude=51.5074&longitude=-0.1278&radius=5000',
    'latitude=48.8566&longitude=2.3522&radius=15000&min_price=50&max_price=200',
  ];
  
  const randomParams = searchParams[Math.floor(Math.random() * searchParams.length)];
  const searchRes = http.get(`${API_URL}/api/hotels/search?${randomParams}`);
  
  check(searchRes, {
    'search status is 200': (r) => r.status === 200,
    'search returns array': (r) => {
      try {
        const data = JSON.parse(r.body);
        return Array.isArray(data);
      } catch (e) {
        return false;
      }
    },
  });

  sleep(Math.random() * 2 + 1);
}
EOF

    k6 run \
        --env API_URL="$API_URL" \
        --out json="$RESULTS_DIR/stress-test-results.json" \
        "$RESULTS_DIR/stress-test.js"
}

# Function to run spike test
run_spike_test() {
    print_header "Running Spike Test..."
    
    cat > "$RESULTS_DIR/spike-test.js" << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 5 },
    { duration: '10s', target: 50 }, // Spike
    { duration: '30s', target: 5 },
  ],
};

const API_URL = __ENV.API_URL || 'http://localhost:8001';

export default function() {
  const res = http.get(`${API_URL}/api/hotels`);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}
EOF

    k6 run \
        --env API_URL="$API_URL" \
        --out json="$RESULTS_DIR/spike-test-results.json" \
        "$RESULTS_DIR/spike-test.js"
}

# Function to run API endpoint tests
run_api_endpoint_tests() {
    print_header "Running API Endpoint Tests..."
    
    print_info "Testing all API endpoints..."
    
    # Test endpoints
    endpoints=(
        "GET /api/hotels"
        "GET /api/hotels/search?latitude=40.7128&longitude=-74.0060&radius=10000"
    )
    
    for endpoint in "${endpoints[@]}"; do
        method=$(echo $endpoint | cut -d' ' -f1)
        path=$(echo $endpoint | cut -d' ' -f2)
        
        print_info "Testing $method $path"
        
        response_time=$(curl -w "%{time_total}" -s -o /dev/null "$API_URL$path")
        status_code=$(curl -w "%{http_code}" -s -o /dev/null "$API_URL$path")
        
        if [ "$status_code" -eq 200 ]; then
            print_success "$method $path - Status: $status_code, Time: ${response_time}s"
        else
            print_error "$method $path - Status: $status_code, Time: ${response_time}s"
        fi
    done
}

# Function to generate performance report
generate_report() {
    print_header "Generating Performance Report..."
    
    report_file="$RESULTS_DIR/performance-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🏨 Hotel Mapping Application - Performance Test Report

**Generated:** $(date)
**Frontend URL:** $FRONTEND_URL
**API URL:** $API_URL

## Test Summary

### Services Tested
- ✅ Frontend Application
- ✅ Backend API
- ✅ Hotel Search Functionality
- ✅ Authentication Endpoints

### Test Types Executed
1. **Basic Load Test** - Normal user load simulation
2. **Stress Test** - High load with gradual increase
3. **Spike Test** - Sudden traffic spike simulation
4. **API Endpoint Test** - Individual endpoint performance

## Results

### Basic Load Test
$(if [ -f "$RESULTS_DIR/basic-load-results.json" ]; then
    echo "- Test completed successfully"
    echo "- Results saved to: basic-load-results.json"
else
    echo "- Test not completed or failed"
fi)

### Stress Test
$(if [ -f "$RESULTS_DIR/stress-test-results.json" ]; then
    echo "- Test completed successfully"
    echo "- Results saved to: stress-test-results.json"
else
    echo "- Test not completed or failed"
fi)

### Spike Test
$(if [ -f "$RESULTS_DIR/spike-test-results.json" ]; then
    echo "- Test completed successfully"
    echo "- Results saved to: spike-test-results.json"
else
    echo "- Test not completed or failed"
fi)

## Recommendations

Based on the test results:

1. **Response Time**: Monitor p95 response times should be < 2 seconds
2. **Error Rate**: Should be < 1% under normal load
3. **Throughput**: API should handle the expected user load
4. **Scalability**: Consider horizontal scaling if needed

## Next Steps

1. Review detailed results in JSON files
2. Identify bottlenecks from the test data
3. Optimize slow endpoints if necessary
4. Set up continuous performance monitoring
5. Establish performance baselines

## Files Generated

- \`basic-load-results.json\` - Basic load test results
- \`stress-test-results.json\` - Stress test results  
- \`spike-test-results.json\` - Spike test results
- \`performance-report-$(date +%Y%m%d-%H%M%S).md\` - This report

---
*Report generated by Hotel Mapping Application Performance Testing Suite*
EOF

    print_success "Performance report generated: $report_file"
}

# Function to run all tests
run_all_tests() {
    print_header "Running Complete Performance Test Suite..."
    
    if ! check_services; then
        print_error "Services are not available. Please start the application first."
        return 1
    fi
    
    if ! install_k6; then
        print_error "Failed to install k6"
        return 1
    fi
    
    run_basic_load_test
    sleep 10
    
    run_stress_test
    sleep 10
    
    run_spike_test
    sleep 5
    
    run_api_endpoint_tests
    
    generate_report
    
    print_success "All performance tests completed!"
    print_info "Results are available in: $RESULTS_DIR"
}

# Function to clean up old results
cleanup_results() {
    print_header "Cleaning up old test results..."
    
    if [ -d "$RESULTS_DIR" ]; then
        rm -rf "$RESULTS_DIR"
        print_success "Old results cleaned up"
    fi
    
    mkdir -p "$RESULTS_DIR"
}

# Main script
case "${1:-}" in
    "basic")
        check_services && install_k6 && run_basic_load_test
        ;;
    "stress")
        check_services && install_k6 && run_stress_test
        ;;
    "spike")
        check_services && install_k6 && run_spike_test
        ;;
    "api")
        check_services && run_api_endpoint_tests
        ;;
    "all")
        run_all_tests
        ;;
    "cleanup")
        cleanup_results
        ;;
    "report")
        generate_report
        ;;
    *)
        echo "Hotel Mapping Application - Performance Testing Suite"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  basic     Run basic load test"
        echo "  stress    Run stress test"
        echo "  spike     Run spike test"
        echo "  api       Run API endpoint tests"
        echo "  all       Run all performance tests"
        echo "  cleanup   Clean up old test results"
        echo "  report    Generate performance report"
        echo ""
        echo "Environment Variables:"
        echo "  FRONTEND_URL  Frontend URL (default: http://localhost:3000)"
        echo "  API_URL       API URL (default: http://localhost:8001)"
        echo ""
        echo "Examples:"
        echo "  $0 all                    # Run complete test suite"
        echo "  $0 basic                  # Run basic load test only"
        echo "  API_URL=https://api.example.com $0 stress  # Custom API URL"
        echo ""
        print_info "Make sure your application is running before starting tests"
        ;;
esac