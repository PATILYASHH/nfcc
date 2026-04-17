"""Web-based dashboard for NFCC PC companion."""

import json
import socket
import threading
import webbrowser
import base64
from http.server import HTTPServer, BaseHTTPRequestHandler
from io import BytesIO

import qrcode


def get_local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def generate_qr_base64(config: dict) -> str:
    data = json.dumps({
        "id": config["id"],
        "name": socket.gethostname(),
        "ip": get_local_ip(),
        "port": config["port"],
        "token": config["pairing_token"],
    })
    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=8, border=2)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="#00B0FF", back_color="#0D1117")
    buf = BytesIO()
    img.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode()


class DashboardState:
    """Shared state between websocket server and dashboard."""
    def __init__(self):
        self.connected_devices = []
        self.action_log = []
        self.status = "Waiting for connection..."

    def add_log(self, action: str, success: bool, detail: str = ""):
        import datetime
        self.action_log.insert(0, {
            "time": datetime.datetime.now().strftime("%H:%M:%S"),
            "action": action,
            "success": success,
            "detail": detail,
        })
        if len(self.action_log) > 50:
            self.action_log = self.action_log[:50]


_state = DashboardState()


def get_state():
    return _state


def build_html(config: dict) -> str:
    qr_b64 = generate_qr_base64(config)
    ip = get_local_ip()
    port = config["port"]
    hostname = socket.gethostname()

    return f"""<!DOCTYPE html>
<html lang="en" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NFCC - NFC Control</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body {{ background: #0D1117; color: #e6edf3; font-family: 'Segoe UI', system-ui, sans-serif; }}
        .card {{ background: #161B22; border: 1px solid #30363D; border-radius: 16px; }}
        .card-header {{ background: transparent; border-bottom: 1px solid #21262D; }}
        .badge-success {{ background: #22C55E20; color: #22C55E; }}
        .badge-fail {{ background: #EF444420; color: #EF4444; }}
        .badge-info {{ background: #3B82F620; color: #3B82F6; }}
        .status-dot {{ width: 10px; height: 10px; border-radius: 50%; display: inline-block; }}
        .status-dot.online {{ background: #22C55E; box-shadow: 0 0 8px #22C55E80; }}
        .status-dot.offline {{ background: #6B7280; }}
        .qr-container {{ background: #0D1117; border-radius: 12px; padding: 16px; display: inline-block; }}
        .action-list {{ max-height: 400px; overflow-y: auto; }}
        .action-item {{ padding: 10px 14px; border-bottom: 1px solid #21262D; }}
        .action-item:last-child {{ border-bottom: none; }}
        .nfc-icon {{ font-size: 2.5rem; color: #00B0FF; }}
        .stat-card {{ background: #161B22; border: 1px solid #30363D; border-radius: 12px; padding: 16px; text-align: center; }}
        .stat-value {{ font-size: 1.8rem; font-weight: 700; }}
        .stat-label {{ font-size: 0.75rem; color: #8B949E; text-transform: uppercase; letter-spacing: 0.5px; }}
        .header-gradient {{ background: linear-gradient(135deg, #0D1117 0%, #161B22 100%); }}
        a {{ color: #58A6FF; }}
        .refresh-btn {{ cursor: pointer; transition: transform 0.3s; }}
        .refresh-btn:hover {{ transform: rotate(180deg); }}
    </style>
</head>
<body>
    <div class="container py-4" style="max-width: 960px;">
        <!-- Header -->
        <div class="d-flex align-items-center mb-4">
            <i class="bi bi-nfc nfc-icon me-3"></i>
            <div>
                <h3 class="mb-0 fw-bold">NFCC <span class="text-secondary fw-normal fs-6">NFC Control</span></h3>
                <small class="text-secondary">{hostname} &bull; {ip}:{port}</small>
            </div>
            <div class="ms-auto">
                <span id="statusDot" class="status-dot offline me-2"></span>
                <span id="statusText" class="text-secondary">Loading...</span>
            </div>
        </div>

        <!-- Stats Row -->
        <div class="row g-3 mb-4">
            <div class="col-4">
                <div class="stat-card">
                    <div class="stat-value text-info" id="statDevices">0</div>
                    <div class="stat-label">Connected</div>
                </div>
            </div>
            <div class="col-4">
                <div class="stat-card">
                    <div class="stat-value text-success" id="statActions">0</div>
                    <div class="stat-label">Actions Run</div>
                </div>
            </div>
            <div class="col-4">
                <div class="stat-card">
                    <div class="stat-value text-warning" id="statUptime">0m</div>
                    <div class="stat-label">Uptime</div>
                </div>
            </div>
        </div>

        <div class="row g-4">
            <!-- QR Code Card -->
            <div class="col-md-5">
                <div class="card h-100">
                    <div class="card-header d-flex align-items-center py-3">
                        <i class="bi bi-qr-code text-info me-2"></i>
                        <span class="fw-semibold">Pair Phone</span>
                    </div>
                    <div class="card-body text-center py-4">
                        <div class="qr-container mb-3">
                            <img src="data:image/png;base64,{qr_b64}" width="200" height="200" alt="QR Code">
                        </div>
                        <p class="text-secondary small mb-1">Scan with NFCC app to connect</p>
                        <code class="text-info">{ip}:{port}</code>
                    </div>
                </div>
            </div>

            <!-- Action Log Card -->
            <div class="col-md-7">
                <div class="card h-100">
                    <div class="card-header d-flex align-items-center py-3">
                        <i class="bi bi-lightning-charge text-warning me-2"></i>
                        <span class="fw-semibold">Action Log</span>
                        <i class="bi bi-arrow-clockwise ms-auto text-secondary refresh-btn" onclick="loadData()"></i>
                    </div>
                    <div class="card-body p-0">
                        <div class="action-list" id="actionLog">
                            <div class="text-center text-secondary py-5">
                                <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                                No actions yet
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Available Actions -->
        <div class="card mt-4">
            <div class="card-header d-flex align-items-center py-3">
                <i class="bi bi-grid-3x3-gap text-success me-2"></i>
                <span class="fw-semibold">Available PC Actions</span>
            </div>
            <div class="card-body">
                <h6 class="text-secondary small mb-2">Window</h6>
                <div class="row g-2 mb-3">
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-arrows-collapse me-2" style="color:#8B5CF6"></i><small>Minimize All</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-arrows-fullscreen me-2" style="color:#8B5CF6"></i><small>Maximize</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-layout-sidebar me-2" style="color:#8B5CF6"></i><small>Snap Left/Right</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-x-circle text-danger me-2"></i><small>Close Window</small></div></div>
                </div>
                <h6 class="text-secondary small mb-2">Sound & Media</h6>
                <div class="row g-2 mb-3">
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-volume-mute me-2" style="color:#EC4899"></i><small>Mute/Unmute</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-volume-up text-warning me-2"></i><small>Volume +/-</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-play-circle text-info me-2"></i><small>Play/Pause</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-skip-forward text-info me-2"></i><small>Next/Prev</small></div></div>
                </div>
                <h6 class="text-secondary small mb-2">System</h6>
                <div class="row g-2 mb-3">
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-lock text-warning me-2"></i><small>Lock PC</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-moon text-info me-2"></i><small>Sleep</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-arrow-repeat text-warning me-2"></i><small>Restart</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-power text-danger me-2"></i><small>Shutdown</small></div></div>
                </div>
                <h6 class="text-secondary small mb-2">Shortcuts</h6>
                <div class="row g-2 mb-3">
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-camera text-info me-2"></i><small>Screenshot</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-folder text-warning me-2"></i><small>File Explorer</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-activity text-danger me-2"></i><small>Task Manager</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-display text-secondary me-2"></i><small>Screen On/Off</small></div></div>
                </div>
                <h6 class="text-secondary small mb-2">Apps & Commands</h6>
                <div class="row g-2">
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-app-indicator text-primary me-2"></i><small>Launch App</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-globe text-info me-2"></i><small>Open URL</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-terminal text-warning me-2"></i><small>Run Command</small></div></div>
                    <div class="col-6 col-md-3"><div class="d-flex align-items-center p-2 rounded" style="background:#161B22"><i class="bi bi-x-circle text-danger me-2"></i><small>Close App</small></div></div>
                </div>
            </div>
        </div>

        <p class="text-center text-secondary small mt-4">
            <i class="bi bi-shield-check me-1"></i> All communication is local network only &bull; No cloud
        </p>
    </div>

    <script>
        const startTime = Date.now();

        function loadData() {{
            fetch('/api/status')
                .then(r => r.json())
                .then(data => {{
                    // Status
                    const dot = document.getElementById('statusDot');
                    const txt = document.getElementById('statusText');
                    const hasDevices = data.devices > 0;
                    dot.className = 'status-dot ' + (hasDevices ? 'online' : 'offline');
                    txt.textContent = data.status;
                    txt.className = hasDevices ? 'text-success' : 'text-secondary';

                    // Stats
                    document.getElementById('statDevices').textContent = data.devices;
                    document.getElementById('statActions').textContent = data.action_count;

                    // Uptime
                    const mins = Math.floor((Date.now() - startTime) / 60000);
                    document.getElementById('statUptime').textContent =
                        mins < 60 ? mins + 'm' : Math.floor(mins/60) + 'h ' + (mins%60) + 'm';

                    // Action log
                    const log = document.getElementById('actionLog');
                    if (data.actions.length === 0) {{
                        log.innerHTML = '<div class="text-center text-secondary py-5"><i class="bi bi-inbox fs-1 d-block mb-2"></i>No actions yet</div>';
                    }} else {{
                        log.innerHTML = data.actions.map(a => `
                            <div class="action-item d-flex align-items-center">
                                <span class="badge ${{a.success ? 'badge-success' : 'badge-fail'}} me-2">
                                    <i class="bi bi-${{a.success ? 'check-lg' : 'x-lg'}}"></i>
                                </span>
                                <div class="flex-grow-1">
                                    <div class="small fw-medium">${{a.action}}</div>
                                    <div class="text-secondary" style="font-size:0.7rem">${{a.detail}}</div>
                                </div>
                                <small class="text-secondary">${{a.time}}</small>
                            </div>
                        `).join('');
                    }}
                }})
                .catch(() => {{}});
        }}

        loadData();
        setInterval(loadData, 2000);
    </script>
</body>
</html>"""


class DashboardHandler(BaseHTTPRequestHandler):
    config = {}

    def do_GET(self):
        if self.path == '/api/status':
            state = get_state()
            data = {
                "status": state.status,
                "devices": len(state.connected_devices),
                "actions": state.action_log,
                "action_count": len(state.action_log),
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        else:
            html = build_html(self.config)
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(html.encode())

    def log_message(self, format, *args):
        pass  # Suppress HTTP logs


def start_dashboard(config: dict, port: int = 8877):
    DashboardHandler.config = config
    server = HTTPServer(('0.0.0.0', port), DashboardHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def open_dashboard(port: int = 8877):
    webbrowser.open(f"http://localhost:{port}")
