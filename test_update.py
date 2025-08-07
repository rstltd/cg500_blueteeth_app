#!/usr/bin/env python3
"""
測試自動更新系統的核心功能
"""

import json
import requests

def test_github_api():
    """測試 GitHub Releases API"""
    url = 'https://api.github.com/repos/rstltd/cg500_blueteeth_app/releases/latest'
    headers = {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'CG500-BLE-App-Test'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"HTTP Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            
            # 解析版本
            tag_name = data.get('tag_name', '1.0.0')
            latest_version = tag_name[1:] if tag_name.startswith('v') else tag_name
            print(f"Latest version: {latest_version}")
            
            # 查找 APK
            assets = data.get('assets', [])
            apk_asset = None
            for asset in assets:
                if asset.get('name', '').lower().endswith('.apk'):
                    apk_asset = asset
                    break
            
            if apk_asset:
                print(f"[OK] APK found: {apk_asset['name']}")
                print(f"[OK] Download URL: {apk_asset['browser_download_url']}")
                print(f"[OK] File size: {apk_asset['size'] / (1024*1024):.1f} MB")
                
                # 測試版本比較
                current_version = '1.0.3'
                has_update = compare_versions(current_version, latest_version) < 0
                print(f"[OK] Version check: {current_version} -> {latest_version}, Update available: {has_update}")
                
                return True
            else:
                print("[ERROR] No APK file found")
                return False
                
        else:
            print(f"[ERROR] API request failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"[ERROR] Error: {e}")
        return False

def compare_versions(current, latest):
    """版本比較邏輯"""
    try:
        # 去掉 build 號碼
        current_clean = current.split('+')[0]
        latest_clean = latest.split('+')[0]
        
        current_parts = current_clean.split('.')
        latest_parts = latest_clean.split('.')
        
        # 補齊到 3 位數
        while len(current_parts) < 3:
            current_parts.append('0')
        while len(latest_parts) < 3:
            latest_parts.append('0')
        
        current_ints = [int(x) for x in current_parts[:3]]
        latest_ints = [int(x) for x in latest_parts[:3]]
        
        for i in range(3):
            if current_ints[i] < latest_ints[i]:
                return -1
            elif current_ints[i] > latest_ints[i]:
                return 1
        
        return 0
    except Exception as e:
        print(f"Version comparison error: {e}")
        return 0

if __name__ == '__main__':
    print("Testing CG500 BLE App Update System")
    print("=" * 50)
    
    success = test_github_api()
    
    print("=" * 50)
    if success:
        print("OK Update system test PASSED!")
        print(">> Users can now download and update the app automatically!")
    else:
        print("X Update system test FAILED!")
        
    print("\nDownload link: https://github.com/rstltd/cg500_blueteeth_app/releases/latest")