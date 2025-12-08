<!doctype html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>تحقق البريد</title>
</head>
<body>
    <h1>جاري معالجة رابط التحقق...</h1>
    <p>سترَ الدمج مع التطبيق يحاول الآن الفتح. إن لم يفتح، اضغط الزر أدناه.</p>

    <button id="openBtn">فتح التطبيق</button>

    <script>
        const full = "{{ $fullUrl }}";
        const appScheme = "minex://verify-email?link=" + encodeURIComponent(full);

        function tryOpen() {
            // أولاً حاول فتح الرابط كـ universal link (نفس عنوان https)
            window.location = full;
            // إذا لم ينجح خلال 800ms حاول فتح الـ custom scheme
            setTimeout(() => { window.location = appScheme; }, 800);
        }

        document.getElementById('openBtn').addEventListener('click', () => {
            tryOpen();
        });

        // محاولة تلقائية
        tryOpen();
    </script>

</body>
</html>
