#!/usr/bin/env python3
"""
CLI Tool for Automated Multi-ABI OTA Patch Packaging and Publishing.
Based on Shorebird-Grade OTA Architecture (docs/ota_automation_architecture.md).

Usage examples:
    python tool/publish_patch.py --version 1.0.9 --channel stable --notes "رفع ایرادات و بهبود کارایی"
    python tool/publish_patch.py --version 1.0.9 --skip-build
"""

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
import zipfile

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(PROJECT_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
PATCHES_OUT_DIR = os.path.join(PROJECT_DIR, 'patches_output')
SUPPORTED_ABIS = ['arm64-v8a', 'armeabi-v7a', 'x86_64']


def calculate_md5(file_path):
    hasher = hashlib.md5()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            hasher.update(chunk)
    return hasher.hexdigest()


def run_cmd(cmd, cwd=PROJECT_DIR):
    cmd_str = ' '.join(cmd) if isinstance(cmd, list) else cmd
    print(f"🚀 Running: {cmd_str}")
    res = subprocess.run(cmd_str, cwd=cwd, shell=True)
    if res.returncode != 0:
        print(f"❌ Command failed with exit code {res.returncode}")
        sys.exit(res.returncode)


def get_base_release_from_pubspec():
    pubspec_path = os.path.join(PROJECT_DIR, 'pubspec.yaml')
    version_line = "1.0.0+1"
    if os.path.exists(pubspec_path):
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('version:'):
                    version_line = line.split('version:', 1)[1].strip()
                    break
    return version_line


import time


class ProgressFile:
    def __init__(self, filepath):
        self._f = open(filepath, 'rb')
        self._total = os.path.getsize(filepath)
        self._read = 0
        self._start = time.time()
        self._last_print = 0

    def read(self, size=-1):
        chunk = self._f.read(size)
        self._read += len(chunk)
        now = time.time()
        if now - self._last_print >= 4.0 or self._read == self._total:
            pct = (self._read / self._total) * 100 if self._total > 0 else 100
            elapsed = now - self._start
            speed = (self._read / 1024) / elapsed if elapsed > 0 else 0
            eta = (self._total - self._read) / (speed * 1024) if speed > 0 else 0
            print(f"   📊 [{pct:5.1f}%] {self._read/(1024*1024):.2f}/{self._total/(1024*1024):.2f} MB | {speed:.1f} KB/s | ETA: {int(eta)}s", flush=True)
            self._last_print = now
        return chunk

    def len(self):
        return self._total

    def close(self):
        self._f.close()


def upload_to_server(patch_path, bundle_path, server_url, patch_version, notes, channel='stable'):
    """
    Deploys the patch to both OTA endpoints on the server:
    1. /api/patches/upload (Admin dashboard & legacy client check)
    2. /api/v1/ota/publish/ (Shorebird-Grade multi-ABI client check)
    """
    import requests
    server_base = server_url.rstrip('/')

    session = requests.Session()
    session.trust_env = False  # Avoid proxy hanging on Windows

    # 1. Upload to /api/patches/upload
    if os.path.exists(patch_path):
        url1 = f"{server_base}/api/patches/upload"
        print(f"\n🌐 [Deploy 1/2] Uploading patch to Admin/Legacy endpoint ({url1})...", flush=True)
        print(f"   Payload: {patch_path} ({os.path.getsize(patch_path)/(1024*1024):.2f} MB)", flush=True)
        data1 = {
            'app_id': 'quran_tafakor',
            'version': patch_version,
            'target_version_code': '1',
            'target_abi': 'multi',
            'is_force': '0',
            'activate': '1',
            'notes': notes,
            'filename': 'patch.zip'
        }
        pf1 = ProgressFile(patch_path)
        try:
            start_t = time.time()
            resp1 = session.post(url1, data=data1, files={'file': ('patch.zip', pf1, 'application/zip')}, timeout=900)
            elapsed = time.time() - start_t
            if resp1.status_code == 200:
                print(f"   ✅ Legacy/Admin Deploy Succeeded in {elapsed:.1f}s (HTTP 200): {resp1.json()}", flush=True)
            else:
                print(f"   ⚠️ Legacy/Admin Deploy status {resp1.status_code}: {resp1.text[:200]}", flush=True)
        except Exception as e:
            print(f"   ❌ Legacy/Admin Upload Error: {e}", flush=True)
        finally:
            pf1.close()

    # 2. Upload to /api/v1/ota/publish/
    if os.path.exists(bundle_path):
        url2 = f"{server_base}/api/v1/ota/publish/"
        print(f"\n🌐 [Deploy 2/2] Uploading bundle to Shorebird OTA endpoint ({url2})...", flush=True)
        print(f"   Payload: {bundle_path} ({os.path.getsize(bundle_path)/(1024*1024):.2f} MB)", flush=True)
        data2 = {'channel': channel}
        pf2 = ProgressFile(bundle_path)
        try:
            start_t = time.time()
            resp2 = session.post(url2, data=data2, files={'bundle': (os.path.basename(bundle_path), pf2, 'application/zip')}, timeout=900)
            elapsed = time.time() - start_t
            if resp2.status_code == 200:
                print(f"   ✅ Shorebird OTA Deploy Succeeded in {elapsed:.1f}s (HTTP 200): {resp2.json()}", flush=True)
            else:
                print(f"   ⚠️ Shorebird OTA Deploy status {resp2.status_code}: {resp2.text[:200]}", flush=True)
        except Exception as e:
            print(f"   ❌ Shorebird OTA Upload Error: {e}", flush=True)
        finally:
            pf2.close()


def main():
    parser = argparse.ArgumentParser(description="Multi-ABI Flutter OTA Patch Publisher")
    parser.add_argument('--version', required=True, help="Patch semantic version (e.g. 1.0.9)")
    parser.add_argument('--channel', default='stable', choices=['stable', 'beta'], help="Release channel")
    parser.add_argument('--notes', default='', help="Changelog / Release notes in Persian or English")
    parser.add_argument('--base-release', default='', help="Host Base release (e.g. 1.0.1+2, default from pubspec.yaml)")
    parser.add_argument('--skip-build', action='store_true', help="Skip 'flutter build apk --release' step")
    parser.add_argument('--target-code', type=int, default=0, help="Explicit targetVersionCode (default auto-derived)")
    parser.add_argument('--server', default='', help="Optional server URL to auto-upload bundle (e.g. http://localhost)")

    args = parser.parse_args()
    patch_version = args.version
    channel = args.channel
    notes = args.notes or f"به‌روزرسانی پچ نسخه {patch_version}"
    base_release = args.base_release or get_base_release_from_pubspec()

    print("═════════════════════════════════════════════════════════════════")
    print(f"📦 [OTA Publish] Packaging Patch v{patch_version} ({channel})")
    print(f"   Base Release: {base_release}")
    print(f"   Notes: {notes}")
    print("═════════════════════════════════════════════════════════════════")

    # Step 1: Build release APK if not skipped
    if not args.skip_build:
        print("🔨 Step 1: Building release APK...")
        run_cmd(['flutter', 'build', 'apk', '--split-per-abi'])
    else:
        print("⏩ Step 1: Skipping flutter build (--skip-build).")

    apk_arm64 = os.path.join(PROJECT_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-arm64-v8a-release.apk')
    if not os.path.exists(APK_PATH) and not os.path.exists(apk_arm64):
        print(f"❌ Release APK not found at {APK_PATH} or {apk_arm64}. Run without --skip-build first.")
        sys.exit(1)

    # Step 2: Pack per-ABI patches using flutter_patcher
    print("🔨 Step 2: Packing per-ABI binaries via flutter_patcher...")
    abi_results = {}

    for abi in SUPPORTED_ABIS:
        abi_out = os.path.join(PATCHES_OUT_DIR, abi)
        os.makedirs(abi_out, exist_ok=True)

        # In split-per-abi builds:
        # Gradle adds offsets: arm64-v8a -> 2000 + build_num, armeabi-v7a -> 1000 + build_num
        base_build_num = 1
        if '+' in base_release:
            try:
                base_build_num = int(base_release.split('+')[1])
            except ValueError:
                pass

        if args.target_code > 0:
            target_code = args.target_code
        else:
            # Auto-map dynamically based on host base release build number
            if abi == 'arm64-v8a':
                target_code = 2000 + base_build_num
            elif abi == 'armeabi-v7a':
                target_code = 1000 + base_build_num
            else:
                target_code = base_build_num

        apk_for_abi = os.path.join(PROJECT_DIR, 'build', 'app', 'outputs', 'flutter-apk', f'app-{abi}-release.apk')
        effective_apk = apk_for_abi if os.path.exists(apk_for_abi) else APK_PATH

        cmd = [
            'dart', 'run', 'flutter_patcher:pack',
            '--apk', effective_apk,
            '--version', patch_version,
            '--target-version-code', str(target_code),
            '--abi', abi,
            '--out', abi_out
        ]
        print(f"   - Packing {abi} using {os.path.basename(effective_apk)} (target-version-code: {target_code})...")
        run_cmd(cmd)

        patch_zip = os.path.join(abi_out, 'patch.zip')
        if not os.path.exists(patch_zip):
            print(f"❌ Warning: patch.zip for {abi} was not generated!")
            continue

        md5_hash = calculate_md5(patch_zip)
        size_bytes = os.path.getsize(patch_zip)
        abi_results[abi] = {
            'file_path': patch_zip,
            'md5': md5_hash,
            'size_bytes': size_bytes,
            'target_code': target_code
        }
        print(f"     ✓ {abi}: MD5={md5_hash}, Size={size_bytes} bytes")

    # Step 3: Create Unified Multi-ABI Bundle
    print("🔨 Step 3: Generating unified bundle (patch_bundle.zip)...")
    bundle_zip_path = os.path.join(PATCHES_OUT_DIR, f'patch_bundle_v{patch_version}.zip')

    manifest = {
        'app_id': 'quran_tafakor',
        'version': patch_version,
        'base_release': base_release,
        'channel': channel,
        'change_log': notes,
        'artifacts': {
            abi: {
                'md5': data['md5'],
                'size_bytes': data['size_bytes'],
                'target_code': data['target_code']
            } for abi, data in abi_results.items()
        }
    }

    manifest_path = os.path.join(PATCHES_OUT_DIR, 'manifest.json')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    with zipfile.ZipFile(bundle_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(manifest_path, 'manifest.json')
        for abi, data in abi_results.items():
            # Add patch.zip or libapp.so under abi folder in the bundle
            zipf.write(data['file_path'], f"{abi}/patch.zip")

    bundle_md5 = calculate_md5(bundle_zip_path)
    bundle_size = os.path.getsize(bundle_zip_path)

    print("\n═════════════════════════════════════════════════════════════════")
    print("🎉 [OTA Publish] Multi-ABI Patch Packaging Complete!")
    print(f"   Bundle Path: {bundle_zip_path}")
    print(f"   Bundle Size: {bundle_size / (1024 * 1024):.2f} MB")
    print(f"   Bundle MD5:  {bundle_md5}")
    print("─────────────────────────────────────────────────────────────────")
    for abi, data in abi_results.items():
        print(f"   📱 {abi.ljust(12)} -> MD5: {data['md5']} ({data['size_bytes']} bytes)")
    print("═════════════════════════════════════════════════════════════════")

    # Step 4: Auto-upload to server if requested
    if args.server:
        primary_patch = abi_results.get('arm64-v8a', {}).get('file_path', '')
        upload_to_server(
            patch_path=primary_patch,
            bundle_path=bundle_zip_path,
            server_url=args.server,
            patch_version=patch_version,
            notes=notes,
            channel=channel
        )


if __name__ == '__main__':
    main()
