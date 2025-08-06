#!/usr/bin/env python3

"""
CG500 BLE App Update Server

A simple update server implementation for the CG500 BLE app.
Provides version checking and APK download functionality.

Usage:
  python update_server.py

Environment variables:
  PORT: Server port (default: 3000)
  APK_DIR: Directory containing APK files (default: ./apks)
  HOST: Server host (default: 0.0.0.0)
"""

import os
import json
import logging
from datetime import datetime
from pathlib import Path
from flask import Flask, request, jsonify, send_file, abort
from werkzeug.exceptions import NotFound

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
CONFIG = {
    'host': os.getenv('HOST', '0.0.0.0'),
    'port': int(os.getenv('PORT', 3000)),
    'apk_dir': Path(os.getenv('APK_DIR', './apks')),
    'debug': os.getenv('DEBUG', 'false').lower() == 'true'
}

# Version configuration - Update this when releasing new versions
VERSION_CONFIG = {
    '1.0.0': {
        'latest_version': '1.1.0',
        'download_url': 'cg500_ble_app_v1.1.0.apk',
        'download_size': 15728640,  # bytes
        'release_notes': '• 新增設備連接穩定性改進\n• 修復藍牙掃描問題\n• UI 介面優化\n• 新增智能通知過濾功能',
        'is_forced': False,
        'update_type': 'recommended',
        'release_date': '2024-01-15T10:00:00Z'
    },
    'default': {
        'latest_version': '1.1.0',
        'download_url': 'cg500_ble_app_v1.1.0.apk',
        'download_size': 15728640,
        'release_notes': '• 新增設備連接穩定性改進\n• 修復藍牙掃描問題\n• UI 介面優化\n• 新增智能通知過濾功能',
        'is_forced': False,
        'update_type': 'recommended',
        'release_date': '2024-01-15T10:00:00Z'
    }
}

def compare_versions(v1, v2):
    """Compare two version strings"""
    def version_tuple(v):
        return tuple(map(int, v.split('.')))
    
    try:
        return (version_tuple(v1) > version_tuple(v2)) - (version_tuple(v1) < version_tuple(v2))
    except ValueError:
        return 0

def get_version_config(current_version):
    """Get version configuration for a specific current version"""
    return VERSION_CONFIG.get(current_version, VERSION_CONFIG['default'])

@app.route('/api/version', methods=['GET'])
def check_version():
    """Version check endpoint"""
    try:
        # Get request headers
        current_version = request.headers.get('Current-Version', '1.0.0')
        current_build = request.headers.get('Current-Build', '1')
        platform = request.headers.get('Platform', 'android')
        
        logger.info(f"Version check - Current: {current_version}+{current_build}, Platform: {platform}")
        
        # Get configuration for this version
        config = get_version_config(current_version)
        latest_version = config['latest_version']
        
        # Check if update is available
        has_update = compare_versions(latest_version, current_version) > 0
        
        response_data = {
            'current_version': current_version,
            'latest_version': latest_version,
            'has_update': has_update
        }
        
        if has_update:
            response_data.update({
                'download_url': config['download_url'],
                'download_size': config['download_size'],
                'release_notes': config['release_notes'],
                'is_forced': config['is_forced'],
                'update_type': config['update_type'],
                'release_date': config['release_date']
            })
            
            logger.info(f"Update available: {current_version} -> {latest_version}")
        else:
            logger.info(f"No update needed for version {current_version}")
        
        return jsonify(response_data)
        
    except Exception as e:
        logger.error(f"Error in version check: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/download/<filename>', methods=['GET'])
def download_apk(filename):
    """APK download endpoint"""
    try:
        # Security: Only allow alphanumeric, dots, dashes, and underscores
        if not filename.replace('.', '').replace('-', '').replace('_', '').isalnum():
            logger.warning(f"Invalid filename requested: {filename}")
            abort(400, 'Invalid filename')
        
        # Ensure filename ends with .apk
        if not filename.endswith('.apk'):
            filename += '.apk'
        
        file_path = CONFIG['apk_dir'] / filename
        
        if not file_path.exists():
            logger.warning(f"APK file not found: {file_path}")
            abort(404, 'File not found')
        
        logger.info(f"Serving APK file: {filename}")
        
        return send_file(
            file_path,
            mimetype='application/vnd.android.package-archive',
            as_attachment=True,
            download_name=filename
        )
        
    except NotFound:
        raise
    except Exception as e:
        logger.error(f"Error serving APK file {filename}: {e}")
        abort(500, 'Internal server error')

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get server statistics (optional)"""
    try:
        apk_files = list(CONFIG['apk_dir'].glob('*.apk')) if CONFIG['apk_dir'].exists() else []
        
        stats = {
            'server_time': datetime.utcnow().isoformat() + 'Z',
            'available_versions': len(apk_files),
            'apk_files': [f.name for f in apk_files],
            'latest_version': VERSION_CONFIG['default']['latest_version']
        }
        
        return jsonify(stats)
        
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'version': '1.0.0'
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

def setup_apk_directory():
    """Create APK directory if it doesn't exist"""
    CONFIG['apk_dir'].mkdir(exist_ok=True)
    
    # Create a sample APK info file
    info_file = CONFIG['apk_dir'] / 'README.txt'
    if not info_file.exists():
        with open(info_file, 'w') as f:
            f.write("Place your APK files in this directory.\n")
            f.write("Filename format: cg500_ble_app_v{version}.apk\n")
            f.write("Example: cg500_ble_app_v1.1.0.apk\n")

def main():
    """Main function"""
    print("🚀 Starting CG500 BLE App Update Server")
    print(f"📁 APK Directory: {CONFIG['apk_dir'].absolute()}")
    print(f"🌐 Server: http://{CONFIG['host']}:{CONFIG['port']}")
    print(f"📊 Health Check: http://{CONFIG['host']}:{CONFIG['port']}/health")
    
    # Setup APK directory
    setup_apk_directory()
    
    # Check for APK files
    if CONFIG['apk_dir'].exists():
        apk_files = list(CONFIG['apk_dir'].glob('*.apk'))
        if apk_files:
            print(f"📱 Found {len(apk_files)} APK files:")
            for apk in apk_files:
                size = apk.stat().st_size
                print(f"   - {apk.name} ({size/1024/1024:.1f} MB)")
        else:
            print("⚠️  No APK files found. Please add APK files to the directory.")
    
    print("\n🔍 API Endpoints:")
    print("   GET  /api/version     - Check for updates")
    print("   GET  /api/download/   - Download APK files")
    print("   GET  /api/stats       - Server statistics")
    print("   GET  /health          - Health check")
    
    print(f"\n🎯 Example version check:")
    print(f"   curl -H 'Current-Version: 1.0.0' -H 'Platform: android' http://localhost:{CONFIG['port']}/api/version")
    
    print("\n" + "="*50)
    
    # Start server
    app.run(
        host=CONFIG['host'],
        port=CONFIG['port'],
        debug=CONFIG['debug']
    )

if __name__ == '__main__':
    main()