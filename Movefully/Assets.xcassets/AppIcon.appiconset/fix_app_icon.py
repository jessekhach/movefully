#!/usr/bin/env python3

from PIL import Image
import sys
import os

try:
    # Check if we're in the right directory
    if not os.path.exists('AppIcon-1024.png'):
        print("AppIcon-1024.png not found in current directory")
        sys.exit(1)
        
    # Open the original image
    img = Image.open('AppIcon-1024.png').convert('RGBA')
    
    # Create new images with proper transparent backgrounds
    # Resize to 120x120 for @2x
    img_120 = img.resize((120, 120), Image.Resampling.LANCZOS)
    img_120.save('AppIcon-60@2x.png', 'PNG')
    
    # Resize to 180x180 for @3x  
    img_180 = img.resize((180, 180), Image.Resampling.LANCZOS)
    img_180.save('AppIcon-60@3x.png', 'PNG')
    
    print('Successfully created app icons with proper transparency')
    print('AppIcon-60@2x.png: 120x120')
    print('AppIcon-60@3x.png: 180x180')
    
except ImportError:
    print('PIL (Pillow) not available. Please install with: pip3 install Pillow')
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1) 