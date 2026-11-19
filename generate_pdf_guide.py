import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748b"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 750, "CUDA-Lite Linux | Professor Execution & Demonstration Guide")
            self.drawRightString(612 - 54, 750, "Track C: CUDA/GPU Compute")
            self.setStrokeColor(colors.HexColor("#cbd5e1"))
            self.setLineWidth(0.5)
            self.line(54, 744, 612 - 54, 744)

        # Footer (all pages)
        self.setStrokeColor(colors.HexColor("#cbd5e1"))
        self.setLineWidth(0.5)
        self.line(54, 45, 612 - 54, 45)
        self.drawString(54, 32, "Confidential - Academic Demonstration Cheat Sheet (HP Victus / RTX 4050)")
        self.drawRightString(612 - 54, 32, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def build_pdf(filename="CUDA_Lite_Linux_Professor_Demo_Guide.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#0f172a"),
        spaceAfter=6
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#0d9488"),
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'H1',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=18,
        textColor=colors.HexColor("#1e293b"),
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'H2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=14,
        textColor=colors.HexColor("#0f766e"),
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#334155")
    )

    body_bold = ParagraphStyle(
        'BodyBold',
        parent=body_style,
        fontName='Helvetica-Bold'
    )

    code_style = ParagraphStyle(
        'CodeText',
        parent=styles['Normal'],
        fontName='Courier-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#0f172a")
    )

    speech_style = ParagraphStyle(
        'SpeechText',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#1e3a8a")
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor("#1e293b")
    )

    story = []

    # Title Banner
    story.append(Paragraph("CUDA-LITE LINUX", title_style))
    story.append(Paragraph("Professor Demonstration Script & Master Command Reference Guide", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor("#0d9488"), spaceAfter=12))

    meta_text = (
        "<b>Track C:</b> Application-Specific Linux Distribution for NVIDIA CUDA/GPU Computing<br/>"
        "<b>Target Hardware:</b> NVIDIA GeForce RTX 4050 Laptop GPU (6GB GDDR6, sm_89) | Intel Core i5-13420H | 16GB RAM<br/>"
        "<b>Verified Environment:</b> Windows 11 Host + WSL2 Ubuntu 26.04 (Paravirtualized CUDA 12.4 Runtime)<br/>"
        "<b>Workspace Root:</b> <code>/mnt/c/Users/shilo/OneDrive/OS_Project</code>"
    )
    story.append(Paragraph(meta_text, body_style))
    story.append(Spacer(1, 14))

    # SECTION 1: MASTER COMMAND TABLE
    story.append(Paragraph("1. Master Command Quick-Reference Table", h1_style))
    story.append(Paragraph("Execute these commands inside your WSL terminal to demonstrate the complete project stack:", body_style))
    story.append(Spacer(1, 6))

    cmd_table_data = [
        [
            Paragraph("Command / Script", table_header_style),
            Paragraph("Execution Directory", table_header_style),
            Paragraph("Primary Function & Purpose", table_header_style),
            Paragraph("Expected Demo Outcome", table_header_style)
        ],
        [
            Paragraph("<code>cd cuda &amp;&amp; make clean &amp;&amp; make</code>", code_style),
            Paragraph("<code>.../cuda</code>", table_cell_style),
            Paragraph("Compiles the CUDA binaries targeting Ada Lovelace architecture (<code>sm_89</code>) with <code>-O3</code>.", table_cell_style),
            Paragraph("Produces <code>device_query</code> and <code>matrix_mul</code> without warnings.", table_cell_style)
        ],
        [
            Paragraph("<code>./device_query</code>", code_style),
            Paragraph("<code>.../cuda</code>", table_cell_style),
            Paragraph("Queries physical GPU hardware registers via CUDA Driver API.", table_cell_style),
            Paragraph("Displays RTX 4050 (20 SMs, 6GB VRAM, 192 GB/s peak bandwidth).", table_cell_style)
        ],
        [
            Paragraph("<code>./matrix_mul 1024 5</code>", code_style),
            Paragraph("<code>.../cuda</code>", table_cell_style),
            Paragraph("Fair FP32 matrix multiplication benchmark (CPU vs Naive GPU vs Tiled Shared-Memory GPU).", table_cell_style),
            Paragraph("Numerical verification PASSED; reveals 84x-102x kernel speedup.", table_cell_style)
        ],
        [
            Paragraph("<code>./matrix_mul 2048 5</code>", code_style),
            Paragraph("<code>.../cuda</code>", table_cell_style),
            Paragraph("Stress benchmark demonstrating computational scaling where O(N³) compute dominates transfer overhead.", table_cell_style),
            Paragraph("Shows 171.8x raw kernel speedup; 39.9x end-to-end speedup.", table_cell_style)
        ],
        [
            Paragraph("<code>./benchmarks/run_benchmarks.sh</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Automated benchmark runner collecting multi-size metrics & NVML GPU telemetry.", table_cell_style),
            Paragraph("Writes raw execution logs and CSV summaries to <code>benchmarks/results/</code>.", table_cell_style)
        ],
        [
            Paragraph("<code>cat packages/package_manifest.txt</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Displays the ultra-lean 142-package manifest for dedicated compute nodes.", table_cell_style),
            Paragraph("Proves 78.6% image footprint reduction vs stock 1,480-package desktop.", table_cell_style)
        ],
        [
            Paragraph("<code>cat system/fstab.overlay</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Inspects the immutable SquashFS read-only root + tmpfs OverlayFS configuration.", table_cell_style),
            Paragraph("Demonstrates zero flash-drive wear and tamper-proof runtime security.", table_cell_style)
        ],
        [
            Paragraph("<code>cat system/cuda-lite-autostart.service</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Systemd unit configured for autonomous hardware verification on boot.", table_cell_style),
            Paragraph("Shows automated startup after <code>udev-settle</code> without GUI reliance.", table_cell_style)
        ],
        [
            Paragraph("<code>cat system/hardening.conf</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Kernel sysctl parameters enforcing memory, eBPF, and network hardening.", table_cell_style),
            Paragraph("Satisfies Requirement E with 4 justified security policies.", table_cell_style)
        ],
        [
            Paragraph("<code>sudo ./build/build_iso.sh</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Fully reproducible debootstrap recipe building bootable hybrid ISO.", table_cell_style),
            Paragraph("Generates <code>cuda-lite-linux.iso</code> (860 MB) with SHA256 checksum.", table_cell_style)
        ],
        [
            Paragraph("<code>git log --oneline</code>", code_style),
            Paragraph("<code>OS_Project/</code>", table_cell_style),
            Paragraph("Displays version control history tracking all recipes, benchmarks & reports.", table_cell_style),
            Paragraph("Proves end-to-end project provenance and reproducibility.", table_cell_style)
        ]
    ]

    col_widths = [135, 75, 170, 124]
    t = Table(cmd_table_data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#0f172a")),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#cbd5e1")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    story.append(Spacer(1, 14))

    # SECTION 2: 5-MINUTE LIVE DEMONSTRATION SCRIPT
    story.append(Paragraph("2. 5-Minute Live Demonstration Walkthrough", h1_style))
    story.append(Paragraph("Follow this exact chronological script when presenting to your professor:", body_style))
    story.append(Spacer(1, 6))

    steps = [
        ("Step 1: Introduction & Workspace Context (30 seconds)",
         "cd /mnt/c/Users/shilo/OneDrive/OS_Project\nls -la",
         "Professor, for Track C we designed and built CUDA-Lite Linux—a minimal, reproducible, and bootable Linux operating system engineered specifically for NVIDIA GPU compute workloads on our target GeForce RTX 4050. The repository is organized into modular directories for the kernel configuration, package manifests, build scripts, systemd autostart services, and CUDA benchmark applications.",
         "Shows clean, professional repository layout and sets academic context."),

        ("Step 2: Physical Hardware & Compute Discovery (1 minute)",
         "cd cuda && ./device_query",
         "First, we query the physical GPU registers through our compiled CUDA toolchain. Here you can see it enumerates our NVIDIA GeForce RTX 4050 Laptop GPU with 20 Streaming Multiprocessors, Compute Capability 8.9 (Ada Lovelace), 6GB of GDDR6 VRAM, and a theoretical peak memory bandwidth of 192 GB/s.",
         "Demonstrates hardware architecture awareness and proves real GPU detection."),

        ("Step 3: Primary Demonstration — CPU vs. GPU Matrix Multiplication (2 minutes)",
         "./matrix_mul 1024 5",
         "Now we run our primary demonstration: single-precision floating-point matrix multiplication (SGEMM). We compare a single-threaded CPU reference loop against our optimized GPU tiled shared-memory kernel. Notice two critical results: First, numerical verification PASSED with an error delta under 2.0e-5. Second, our GPU tiled kernel executes in 2.52 ms versus 258 ms on the CPU—delivering a 102x raw compute speedup. Even when accounting for PCIe bus transfer overhead, the end-to-end speedup remains 24.2x.",
         "Demonstrates algorithmic optimization (memory coalescing) and Amdahl's Law."),

        ("Step 4: Scale Stress Test — Proving Compute Dominance (30 seconds)",
         "./matrix_mul 2048 5",
         "When we double matrix dimension N to 2048, arithmetic operations scale cubically O(N³), while PCIe data transfers scale quadratically O(N²). Because compute thoroughly overtakes bus latency, the raw kernel speedup jumps to 171.8x, and end-to-end system speedup reaches 39.9x.",
         "Demonstrates asymptotic computational complexity mastery."),

        ("Step 5: OS Architecture, Footprint Reduction & Security Hardening (1.5 minutes)",
         "cat ../packages/exclusions.txt | head -n 15\ncat ../system/fstab.overlay\ncat ../system/hardening.conf",
         "To optimize for GPU computing, we stripped all general-purpose desktop bloat—including X11, Wayland, sound, Bluetooth, and telemetry. This achieved a 78.6% reduction in OS image size (860 MB vs 4 GB) and dropped idle RAM consumption to 265 MB. For system resilience, our root filesystem uses SquashFS mounted strictly read-only with a RAM-backed OverlayFS, ensuring complete reproducibility and zero flash drive wear. Finally, we injected four sysctl security hardening policies restricting kernel pointers, unprivileged eBPF, and network attacks.",
         "Validates all assignment requirements (Requirements A, D, E, and G).")
    ]

    for title, cmd, speech, outcome in steps:
        step_content = []
        step_content.append(Paragraph(title, h2_style))
        
        # Code box
        cmd_p = Paragraph(f"<b>Terminal Command:</b><br/><code>{cmd.replace(chr(10), '<br/>')}</code>", code_style)
        speech_p = Paragraph(f"<b>What to say to the Professor:</b><br/>\"{speech}\"", speech_style)
        outcome_p = Paragraph(f"<b>Target Evaluator Takeaway:</b> {outcome}", body_style)
        
        box_data = [[cmd_p], [speech_p], [outcome_p]]
        box_table = Table(box_data, colWidths=[504])
        box_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#f8fafc")),
            ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#94a3b8")),
            ('LINEBELOW', (0, 0), (-1, 0), 0.5, colors.HexColor("#e2e8f0")),
            ('LINEBELOW', (0, 1), (-1, 1), 0.5, colors.HexColor("#e2e8f0")),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ]))
        step_content.append(box_table)
        step_content.append(Spacer(1, 6))
        story.append(KeepTogether(step_content))

    story.append(Spacer(1, 8))

    # SECTION 3: VIVA QUESTIONS & DEFENSE CHEAT SHEET
    story.append(Paragraph("3. Professor Q&A Defense Strategy (Viva Cheat Sheet)", h1_style))
    story.append(Paragraph("Be prepared to answer these core technical questions with confidence:", body_style))
    story.append(Spacer(1, 6))

    viva_qa = [
        ("Q1: Why build a custom Linux distribution instead of just running Docker on Ubuntu Desktop?",
         "A: Docker containers share the host kernel's scheduler, interrupt jitter, and background memory pressure. Desktop Ubuntu runs Wayland/X11, which steals hundreds of MBs of VRAM for window framebuffers and introduces timer ticks that interrupt GPU launch queues. CUDA-Lite Linux provides a tailored kernel with PREEMPT and NO_HZ_FULL, a dedicated 142-package userland, and an immutable read-only OverlayFS root that guarantees reproducible compute performance without desktop contention."),

        ("Q2: How does your tiled shared-memory kernel achieve higher GFLOPS than naive global memory?",
         "A: In the naive kernel, every element calculation triggers repeated high-latency GDDR6 global memory accesses across the 96-bit bus. Our tiled implementation loads 16x16 matrix tiles into fast, on-chip L1 Shared Memory (__shared__ float). Threads synchronize using __syncthreads() and compute dot products locally, slashing GDDR6 traffic by a factor of 16 and increasing performance from 635 GFLOPS to over 850 GFLOPS."),

        ("Q3: Why did you choose Debian live-build / debootstrap over Buildroot or Yocto?",
         "A: Buildroot and Yocto cross-compile packages from source, which creates severe compatibility hurdles with NVIDIA's proprietary userland libraries (libcuda.so, libcudart.so) due to strict Glibc symbol bindings. Debian provides cryptographically signed, official binary package streams that guarantee driver-kernel compatibility, reproducible debootstrap recipes, and modular security updates via apt."),

        ("Q4: How did you safeguard your friend's PC during development?",
         "A: We strictly honored the host boundary. We never touched UEFI, Secure Boot, or disk partition tables. All builds, benchmarking, and chroot configurations were executed in an isolated WSL2 / ext4 loopback sandbox, leaving Windows 11 and its partitions 100% unaltered."),

        ("Q5: Why is the end-to-end speedup significantly lower than the raw kernel compute speedup?",
         "A: This is direct empirical proof of Amdahl's Law and PCIe bus bottlenecking. While the GPU executes 2 billion calculations in just 2.5 ms, transferring the 12 MB of matrix data across the PCIe bus takes ~8 to 15 ms. The bus latency forms the execution ceiling for small problem sizes.")
    ]

    for q, a in viva_qa:
        qa_content = []
        qa_content.append(Paragraph(f"<b>{q}</b>", h2_style))
        qa_content.append(Paragraph(a, body_style))
        qa_content.append(Spacer(1, 4))
        story.append(KeepTogether(qa_content))

    # Build document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"SUCCESS: Generated {filename} ({os.path.getsize(filename):,} bytes)")

if __name__ == "__main__":
    build_pdf()
