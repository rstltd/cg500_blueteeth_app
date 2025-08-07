#!/usr/bin/env python3
"""
測試版本比較邏輯
"""

def compare_versions(version1, version2):
    """版本比較邏輯 (Python版本，模擬Dart實現)"""
    try:
        # 移除build號碼
        v1_clean = version1.split('+')[0]
        v2_clean = version2.split('+')[0]
        
        v1_parts = [int(x) for x in v1_clean.split('.')]
        v2_parts = [int(x) for x in v2_clean.split('.')]
        
        # 確保兩個列表都有至少3個元素 (major.minor.patch)
        while len(v1_parts) < 3:
            v1_parts.append(0)
        while len(v2_parts) < 3:
            v2_parts.append(0)
        
        for i in range(3):
            if v1_parts[i] < v2_parts[i]:
                return -1
            elif v1_parts[i] > v2_parts[i]:
                return 1
        
        # 如果主版本相同，比較build號碼
        v1_build = version1.split('+')
        v2_build = version2.split('+')
        
        if len(v1_build) > 1 and len(v2_build) > 1:
            try:
                build1 = int(v1_build[1])
                build2 = int(v2_build[1])
                if build1 < build2:
                    return -1
                elif build1 > build2:
                    return 1
            except:
                pass
        elif len(v2_build) > 1:
            return -1  # version2 有build號碼，version1沒有
        elif len(v1_build) > 1:
            return 1   # version1 有build號碼，version2沒有
        
        return 0
    except Exception as e:
        print(f"版本比較錯誤: {e}")
        return 0

def test_version_comparisons():
    """測試不同版本比較情況"""
    test_cases = [
        ("1.0.3", "1.0.4+5", "Current < Latest (patch update)"),
        ("1.0.4", "1.0.4+5", "Current < Latest (build update)"),
        ("1.0.4+5", "1.0.4+5", "Current = Latest"),
        ("1.0.5", "1.0.4+5", "Current > Latest"),
        ("1.0.4+3", "1.0.4+5", "Current < Latest (build diff)"),
        ("2.0.0", "1.0.4+5", "Current > Latest (major diff)"),
        ("1.1.0", "1.0.4+5", "Current > Latest (minor diff)"),
    ]
    
    print("版本比較測試結果:")
    print("=" * 60)
    
    for current, latest, description in test_cases:
        result = compare_versions(current, latest)
        has_update = result < 0
        
        print(f"當前版本: {current:10} | 最新版本: {latest:10}")
        print(f"比較結果: {result:2} | 有更新: {'是' if has_update else '否':2} | {description}")
        print("-" * 60)

if __name__ == '__main__':
    print("CG500 BLE App - 版本比較邏輯測試")
    print("=" * 60)
    test_version_comparisons()
    
    # 測試實際應用場景
    print("\n實際場景測試:")
    print("=" * 60)
    current_app_version = "1.0.4+5"  # 目前pubspec.yaml中的版本
    github_version = "1.0.4+5"      # GitHub上的最新版本
    
    result = compare_versions(current_app_version, github_version)
    has_update = result < 0
    
    print(f"應用當前版本: {current_app_version}")
    print(f"GitHub最新版本: {github_version}")
    print(f"比較結果: {result}")
    print(f"應該顯示更新: {'是' if has_update else '否'}")
    
    if not has_update:
        print("\n分析: 由於版本相同，不應該顯示更新對話框")
        print("如果仍然看到'Update Check Failed'，可能是其他問題")