#!/usr/bin/env python3
"""
清理混亂的GitHub Releases
"""

import subprocess
import sys

def cleanup_releases():
    """清理混亂的版本發布"""
    print("清理GitHub Releases...")
    print("=" * 50)
    
    # 要刪除的混亂版本
    versions_to_delete = [
        "v1.0.4+5",
        "v1.0.5+6", 
        "v1.1.0",
        "v1.1.1+2",
        "v1.1.2+3"
    ]
    
    print("將刪除以下混亂的版本:")
    for version in versions_to_delete:
        print(f"  - {version}")
    
    print("\n確認刪除? (y/N): ", end="")
    if input().lower() != 'y':
        print("取消操作")
        return
    
    # 刪除每個版本
    for version in versions_to_delete:
        try:
            print(f"\n刪除 {version}...")
            result = subprocess.run([
                "gh", "release", "delete", version, "--yes"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✓ {version} 已刪除")
            else:
                print(f"✗ {version} 刪除失敗: {result.stderr}")
                
        except Exception as e:
            print(f"✗ 刪除 {version} 時出錯: {e}")
    
    print(f"\n清理完成！")
    print(f"保留的版本:")
    print(f"  - v1.0.3+4 (舊版本)")
    print(f"  - 即將創建 v2.0.0 (最終版本)")

if __name__ == '__main__':
    cleanup_releases()