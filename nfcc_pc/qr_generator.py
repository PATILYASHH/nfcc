"""Generates and displays QR code for phone pairing."""

import json
import socket
import tkinter as tk
from io import BytesIO

import qrcode
from PIL import Image, ImageTk


def get_local_ip() -> str:
    """Get the machine's local IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def generate_qr_data(config: dict) -> str:
    """Generate the JSON payload for the QR code."""
    return json.dumps({
        "id": config["id"],
        "name": socket.gethostname(),
        "ip": get_local_ip(),
        "port": config["port"],
        "token": config["pairing_token"],
    })


def generate_qr_image(data: str, size: int = 300) -> Image.Image:
    """Generate a QR code PIL Image."""
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="white", back_color="black")
    return img.resize((size, size), Image.Resampling.NEAREST)


def show_qr_window(config: dict):
    """Show a tkinter window with the pairing QR code."""
    data = generate_qr_data(config)
    img = generate_qr_image(data, size=350)

    root = tk.Tk()
    root.title("NFCC - Pair with Phone")
    root.configure(bg="#000000")
    root.resizable(False, False)

    # Center window
    w, h = 420, 500
    x = (root.winfo_screenwidth() - w) // 2
    y = (root.winfo_screenheight() - h) // 2
    root.geometry(f"{w}x{h}+{x}+{y}")

    # Title
    title = tk.Label(
        root, text="NFCC", font=("Segoe UI", 24, "bold"),
        fg="white", bg="#000000"
    )
    title.pack(pady=(20, 5))

    subtitle = tk.Label(
        root, text="Scan this QR code with the NFCC app",
        font=("Segoe UI", 11), fg="#9CA3AF", bg="#000000"
    )
    subtitle.pack(pady=(0, 15))

    # QR Code
    photo = ImageTk.PhotoImage(img)
    qr_label = tk.Label(root, image=photo, bg="#000000")
    qr_label.image = photo  # keep reference
    qr_label.pack()

    # IP info
    ip_text = f"{get_local_ip()}:{config['port']}"
    ip_label = tk.Label(
        root, text=ip_text, font=("Consolas", 12),
        fg="#4B5563", bg="#000000"
    )
    ip_label.pack(pady=(15, 5))

    close_btn = tk.Button(
        root, text="Close", command=root.destroy,
        font=("Segoe UI", 10), fg="black", bg="white",
        relief="flat", padx=20, pady=5
    )
    close_btn.pack(pady=(5, 20))

    root.mainloop()
