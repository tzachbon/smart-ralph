#!/usr/bin/env python3
"""Run the shared prototype harness helper from the Claude package."""

from __future__ import annotations

import os
import sys
from pathlib import Path


TARGET = Path(__file__).resolve().parents[3] / "ralph-specum-codex" / "scripts" / "prototype_harness.py"
os.execv(sys.executable, [sys.executable, str(TARGET), *sys.argv[1:]])
