<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تحميل التطبيق</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #00b4db 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 30px;
            padding: 40px 30px;
            max-width: 450px;
            width: 100%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            text-align: center;
            animation: fadeIn 0.8s ease;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .logo-container {
            width: 140px;
            height: 140px;
            margin: 0 auto 30px;
            border-radius: 30px;
            background: linear-gradient(135deg, #667eea 0%, #00b4db 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
            position: relative;
            overflow: hidden;
        }

        .logo-container::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: linear-gradient(45deg, transparent, rgba(255, 255, 255, 0.3), transparent);
            animation: shine 3s infinite;
        }

        @keyframes shine {
            0% { transform: translateX(-100%) translateY(-100%) rotate(45deg); }
            100% { transform: translateX(100%) translateY(100%) rotate(45deg); }
        }

        .logo-container img {
            max-width: 90%;
            max-height: 90%;
            border-radius: 20px;
            position: relative;
            z-index: 1;
        }

        /* إذا لم يتم وضع لوغو، سيظهر هذا النص */
        .logo-placeholder {
            color: white;
            font-size: 18px;
            font-weight: bold;
            text-align: center;
            padding: 20px;
        }

        h1 {
            color: #2d3748;
            font-size: 28px;
            margin-bottom: 15px;
            font-weight: 700;
        }

        .description {
            color: #718096;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 35px;
        }

        .download-btn {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            border: none;
            padding: 18px 50px;
            font-size: 18px;
            font-weight: bold;
            border-radius: 50px;
            cursor: pointer;
            box-shadow: 0 10px 25px rgba(16, 185, 129, 0.4);
            transition: all 0.3s ease;
            width: 100%;
            max-width: 300px;
        }

        .download-btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 15px 35px rgba(16, 185, 129, 0.5);
        }

        .download-btn:active {
            transform: translateY(-1px);
        }

        .features {
            margin-top: 40px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        .feature {
            background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
            padding: 20px;
            border-radius: 15px;
            border-left: 4px solid #667eea;
        }

        .feature-icon {
            font-size: 30px;
            margin-bottom: 10px;
        }

        .feature-text {
            color: #2d3748;
            font-size: 14px;
            font-weight: 600;
        }

        @media (max-width: 480px) {
            .container {
                padding: 30px 20px;
            }

            h1 {
                font-size: 24px;
            }

            .logo-container {
                width: 120px;
                height: 120px;
            }

            .features {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- مكان وضع اللوغو -->
        <div class="logo-container" id="logoContainer">
            <!-- ضع صورة اللوغو هنا -->
            <img src="logo.png" alt="App Logo" id="appLogo">
        </div>

        <h1>حمّل التطبيق الآن</h1>
        <p class="description">
            استمتع بتجربة فريدة ومميزة مع تطبيقنا السوري الجديد. سريع، سهل الاستخدام، ومصمم خصيصاً لك.
        </p>

        <!-- زر التحميل -->
        <button class="download-btn" onclick="downloadApp()">
            📱 تحميل التطبيق
        </button>

        <div class="features">
            <div class="feature">
                <div class="feature-icon">⚡</div>
                <div class="feature-text">سريع وسلس</div>
            </div>
            <div class="feature">
                <div class="feature-icon">🔒</div>
                <div class="feature-text">آمن ومحمي</div>
            </div>
            <div class="feature">
                <div class="feature-icon">🎨</div>
                <div class="feature-text">تصميم عصري</div>
            </div>
            <div class="feature">
                <div class="feature-icon">💡</div>
                <div class="feature-text">سهل الاستخدام</div>
            </div>
        </div>
    </div>

    <script>
        function downloadApp() {
            // ضع هنا رابط ملف APK الخاص بك
            const appUrl = 'minex.apk'; // غيّر هذا إلى اسم ملف التطبيق الخاص بك
            
            // إنشاء رابط تحميل مؤقت
            const link = document.createElement('a');
            link.href = appUrl;
            link.download = 'minex.apk'; // اسم الملف عند التحميل
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    </script>
</body>
</html>