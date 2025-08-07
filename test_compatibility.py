#!/usr/bin/env python3
"""
測試版本相容性
"""

def test_old_version_compatibility():
    """測試舊版本是否能理解新版本號"""
    print("測試1.0.3+4版本的相容性")
    print("=" * 40)
    
    # 模擬舊版本的版本比較邏輯
    def old_compare_versions(version1, version2):
        """舊版本的比較邏輯"""
        try:
            v1_parts = [int(x) for x in version1.split('.')]
            v2_parts = [int(x) for x in version2.split('.')]
            
            max_length = max(len(v1_parts), len(v2_parts))
            
            for i in range(max_length):
                v1 = v1_parts[i] if i < len(v1_parts) else 0
                v2 = v2_parts[i] if i < len(v2_parts) else 0
                
                if v1 < v2:
                    return -1
                elif v1 > v2:
                    return 1
            
            return 0
            
        except Exception as e:
            print(f"錯誤: {e}")
            raise e
    
    test_cases = [
        ("1.0.5+6", "會失敗 - 包含+號"),
        ("1.1.0", "應該成功 - 純數字版本"),
        ("1.2.0", "應該成功 - 純數字版本"),
    ]
    
    current_version = "1.0.3+4"
    print(f"當前版本: {current_version}")
    print()
    
    for latest_version, expected in test_cases:
        print(f"測試版本: {latest_version} - {expected}")
        try:
            # 模擬舊版本的處理方式
            current_clean = current_version.split('+')[0]  # "1.0.3"
            result = old_compare_versions(latest_version, current_clean)
            has_update = result > 0
            print(f"  結果: {'有更新' if has_update else '無更新'}")
            print(f"  狀態: 成功")
        except Exception as e:
            print(f"  結果: 處理失敗")
            print(f"  錯誤: {e}")
        print()
    
    print("結論:")
    print("- 使用1.1.0格式可以被舊版本正確處理")
    print("- 避免使用+號可以防止int.parse錯誤")

if __name__ == '__main__':
    test_old_version_compatibility()