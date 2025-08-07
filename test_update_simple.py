#!/usr/bin/env python3
"""
簡單的更新系統測試
"""

import json
import requests

def test_update_check():
    """測試更新檢查功能"""
    print("測試CG500 BLE App更新檢查...")
    print("=" * 50)
    
    current_version = "1.0.3+4"  # pubspec.yaml中的版本
    current_clean = current_version.split('+')[0]
    
    print(f"當前應用版本: {current_version}")
    print(f"主版本號: {current_clean}")
    
    try:
        # 呼叫GitHub API
        print("\n檢查GitHub Releases...")
        url = 'https://api.github.com/repos/rstltd/cg500_blueteeth_app/releases/latest'
        response = requests.get(url, headers={
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'CG500-BLE-App-Test'
        }, timeout=10)
        
        if response.status_code != 200:
            print(f"API請求失敗: {response.status_code}")
            return False
        
        print("API請求成功")
        data = response.json()
        
        # 解析版本
        tag_name = data.get('tag_name', '1.0.0')
        latest_version = tag_name[1:] if tag_name.startswith('v') else tag_name
        
        print(f"GitHub標籤: {tag_name}")
        print(f"最新版本: {latest_version}")
        
        # 檢查APK
        assets = data.get('assets', [])
        apk_found = False
        for asset in assets:
            if asset.get('name', '').lower().endswith('.apk'):
                apk_found = True
                print(f"APK文件: {asset['name']}")
                print(f"大小: {asset['size'] / (1024*1024):.1f} MB")
                break
        
        if not apk_found:
            print("錯誤: 未找到APK文件")
            return False
        
        # 版本比較
        has_update = compare_versions(current_version, latest_version)
        
        print(f"\n版本比較結果:")
        print(f"當前: {current_version}")
        print(f"最新: {latest_version}")
        print(f"有更新: {has_update}")
        
        if has_update:
            print("\n結論: 應該顯示更新對話框")
        else:
            print("\n結論: 不應該顯示更新對話框")
        
        return True
        
    except Exception as e:
        print(f"測試失敗: {e}")
        return False

def compare_versions(current, latest):
    """版本比較函數"""
    try:
        current_clean = current.split('+')[0]
        latest_clean = latest.split('+')[0]
        
        current_parts = [int(x) for x in current_clean.split('.')]
        latest_parts = [int(x) for x in latest_clean.split('.')]
        
        # 補齊到3位數
        while len(current_parts) < 3:
            current_parts.append(0)
        while len(latest_parts) < 3:
            latest_parts.append(0)
        
        # 比較主版本號
        for i in range(3):
            if latest_parts[i] > current_parts[i]:
                return True
            elif latest_parts[i] < current_parts[i]:
                return False
        
        # 主版本相同，比較build號碼
        current_build = current.split('+')
        latest_build = latest.split('+')
        
        if len(current_build) > 1 and len(latest_build) > 1:
            try:
                build1 = int(current_build[1])
                build2 = int(latest_build[1])
                return build2 > build1
            except:
                pass
        elif len(latest_build) > 1:
            return True
        
        return False
        
    except Exception as e:
        print(f"版本比較錯誤: {e}")
        return False

if __name__ == '__main__':
    success = test_update_check()
    
    print("\n" + "=" * 50)
    if success:
        print("測試完成")
        print("如果Flutter應用顯示'Update Check Failed'，")
        print("可能是應用內部的網路服務或異常處理問題")
    else:
        print("測試失敗")
    
    print("\nGitHub下載連結:")
    print("https://github.com/rstltd/cg500_blueteeth_app/releases/latest")