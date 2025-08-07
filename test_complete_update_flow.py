#!/usr/bin/env python3
"""
完整的更新系統測試，模擬Flutter應用的更新檢查邏輯
"""

import json
import requests
import sys

def simulate_flutter_update_check():
    """模擬Flutter應用的更新檢查過程"""
    print("模擬Flutter應用更新檢查過程...")
    print("=" * 60)
    
    # 模擬應用當前版本（從pubspec.yaml）
    current_version = "1.0.3+4"
    current_version_clean = current_version.split('+')[0]  # "1.0.3"
    
    print(f"應用當前版本: {current_version} (主版本: {current_version_clean})")
    
    try:
        # 1. 模擬UpdateService.checkForUpdates()
        print("\n1. 呼叫GitHub Releases API...")
        response = requests.get(
            'https://api.github.com/repos/rstltd/cg500_blueteeth_app/releases/latest',
            headers={
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'CG500-BLE-App',
            },
            timeout=10
        )
        
        if response.status_code != 200:
            print(f"[ERROR] API請求失敗: {response.status_code}")
            return False
        
        print("[OK] API請求成功")
        
        # 2. 解析響應數據
        data = response.json()
        tag_name = data.get('tag_name', '1.0.0')
        
        # 模擬_cleanVersionTag
        latest_version = tag_name[1:] if tag_name.startswith('v') else tag_name
        print(f"GitHub標籤: {tag_name} -> 清理後版本: {latest_version}")
        
        # 3. 查找APK文件
        assets = data.get('assets', [])
        apk_asset = None
        for asset in assets:
            if asset.get('name', '').lower().endswith('.apk'):
                apk_asset = asset
                break
        
        if not apk_asset:
            print("❌ 未找到APK文件")
            return False
        
        print(f"✅ 找到APK: {apk_asset['name']}")
        print(f"   下載URL: {apk_asset['browser_download_url']}")
        print(f"   文件大小: {apk_asset['size'] / (1024*1024):.1f} MB")
        
        # 4. 版本比較邏輯（模擬UpdateInfo.hasUpdate）
        has_update = compare_versions_flutter_style(current_version, latest_version)
        
        print(f"\n版本比較結果:")
        print(f"當前版本: {current_version}")
        print(f"最新版本: {latest_version}")
        print(f"有更新: {'是' if has_update else '否'}")
        
        if has_update:
            print("\n✅ 應該顯示更新對話框")
            
            # 5. 模擬UpdateInfo創建
            update_info = {
                'current_version': current_version,
                'latest_version': latest_version,
                'download_url': apk_asset['browser_download_url'],
                'download_size': apk_asset['size'],
                'release_notes': data.get('body', 'No release notes available'),
                'has_update': True
            }
            
            print("\n更新信息:")
            for key, value in update_info.items():
                if key == 'release_notes':
                    continue  # Skip release notes for brevity
                print(f"  {key}: {value}")
            
        else:
            print("\n✅ 版本已是最新，不應顯示更新對話框")
        
        return True
        
    except Exception as e:
        print(f"❌ 更新檢查失敗: {e}")
        return False

def compare_versions_flutter_style(current, latest):
    """模擬Flutter UpdateInfo.hasUpdate邏輯"""
    try:
        # 移除build號碼 
        current_clean = current.split('+')[0]
        latest_clean = latest.split('+')[0]
        
        current_parts = [int(x) for x in current_clean.split('.')]
        latest_parts = [int(x) for x in latest_clean.split('.')]
        
        # 確保兩個列表都有至少3個元素
        while len(current_parts) < 3:
            current_parts.append(0)
        while len(latest_parts) < 3:
            latest_parts.append(0)
        
        for i in range(3):
            if latest_parts[i] > current_parts[i]:
                return True
            elif latest_parts[i] < current_parts[i]:
                return False
        
        # 如果主版本相同，比較build號碼
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
            return True  # 最新版本有build號碼，當前版本沒有
        
        return False
        
    except Exception as e:
        print(f"版本比較錯誤: {e}")
        return False

def diagnose_update_check_failed():
    """診斷可能的Update Check Failed原因"""
    print("\n診斷可能的問題:")
    print("=" * 60)
    
    issues = []
    
    # 檢查網路連線
    try:
        response = requests.get('https://google.com', timeout=5)
        print("✅ 網路連線正常")
    except:
        issues.append("❌ 網路連線問題")
    
    # 檢查GitHub API可達性
    try:
        response = requests.get('https://api.github.com', timeout=5)
        if response.status_code == 200:
            print("✅ GitHub API可達")
        else:
            issues.append(f"❌ GitHub API返回: {response.status_code}")
    except Exception as e:
        issues.append(f"❌ GitHub API不可達: {e}")
    
    # 檢查特定倉庫
    try:
        response = requests.get(
            'https://api.github.com/repos/rstltd/cg500_blueteeth_app',
            timeout=5
        )
        if response.status_code == 200:
            print("✅ 倉庫可達")
        elif response.status_code == 404:
            issues.append("❌ 倉庫不存在或私有")
        else:
            issues.append(f"❌ 倉庫API錯誤: {response.status_code}")
    except Exception as e:
        issues.append(f"❌ 倉庫API請求失敗: {e}")
    
    if issues:
        print("\n發現的問題:")
        for issue in issues:
            print(f"  {issue}")
    else:
        print("\n✅ 未發現網路或API問題")
        print("   'Update Check Failed'可能來自Flutter應用內部邏輯")

if __name__ == '__main__':
    print("CG500 BLE App - 完整更新流程測試")
    print("=" * 60)
    
    success = simulate_flutter_update_check()
    
    diagnose_update_check_failed()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ 更新系統測試通過")
        print("   如果Flutter應用仍顯示'Update Check Failed'，")
        print("   可能是Flutter應用內部的異常處理或網路服務問題")
    else:
        print("❌ 更新系統測試失敗")
        print("   請檢查網路連線和GitHub倉庫設定")
    
    print(f"\n測試結果摘要:")
    print(f"- 當前pubspec.yaml版本: 1.0.3+4")
    print(f"- GitHub最新版本: 1.0.4+5")  
    print(f"- 預期行為: 應該顯示更新對話框")
    print(f"- 下載連結: https://github.com/rstltd/cg500_blueteeth_app/releases/latest")