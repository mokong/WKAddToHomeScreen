# WKAddToHomeScreen

# [iOS APP添加桌面快捷方式](https://morganwang.cn/)

## 背景

新接到一个需求，需要APP内的某些功能，能够把入口添加到桌面，点击桌面到入口可以直接跳转APP对应界面（类似于下面这张示例图），于是就做了一番调研。

其实很多APP目前都已经实现了类似的功能，比如支付宝、云闪付等等，其中的每一个独立功能都可以单独添加到桌面，所以网上有很多实现的方法，笔者做的是整理和试错。

<!--more-->


<img src="https://i.loli.net/2021/04/22/wn137cohlfDUpKN.png" width="50%" height="50%">


## 实现

首先，添加到桌面功能的操作流程是：

客户端打开APP -> 进入到对应到APP功能模块 -> 点击添加快捷方式到桌面按钮 -> 跳转浏览器，并加载引导页面，点击分享，选择添加到主屏幕 -> 从主屏幕点击刚刚添加到快捷功能，跳转到APP的对应界面。

![iOS开发内部功能生成桌面快捷方式.png](https://i.loli.net/2021/04/22/H9hdM1rPgIvaEqc.png)


根据笔者了解到的信息，目前实现这种功能，大致可以分为两种实现方式：

方法一：H5提供网页，每个不同的功能提供不同的网页，服务端返回这些网页的URL，客户端配置打开URL Scheme，然后使用Safari直接加载URL，加载的网页中根据进入方式的不同，自动重定向打开APP的URL Scheme。

方法二：H5提供通用的网页，客户端替换通用网页中的内容，比如标题、图标等，并转为DataURI格式，服务端提供接口URL，客户端配置打开URL Scheme，使用Safari加载，接口返回强制重定向加载DataURI数据

其中有作者分类了第三种方式，即客户端使用HttpServer，但笔者看来，无论是服务端返回URL还是客户端使用HttpServer，其实是服务端的不同实现方式，故而没有单独分类。


### 准备

**第一步** 客户端：iOS 打开已有Xcode项目，选中Target，添加URL Scheme，这个URL Scheme是自己定义的，在这个地方定义了xxx之后，可以通过在浏览器中输入xxx://来唤起APP，比如笔者定义了一个mkaddtohomescreen，然后在浏览器中输入mkaddtohomescreen://，就会弹出是否打开对应APP的提示

<img src="https://i.loli.net/2021/04/23/Un47sFZaxi6GJC5.png" width="80%" height="80%">



<img src="https://i.loli.net/2021/04/23/W4zIUYMdHluxS3A.png" width="50%" height="50%">



定义好了Scheme之后，可以考虑Scheme添加参数的问题，通过在scheme后添加参数，在Appdelegate中applicaiton:open:options:方法拦截到，根据对应参数跳转不同界面

> 比如Scheme为mkaddtohomescreen://page/view1，在applicaiton:open:options:中，url.absouluteString = mkaddtohomescreen://page/view1，url.host = page，url.path = /view1，所以可以根据path的不同跳转不同的界面。


``` Swift

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let navController = window?.rootViewController as? UINavigationController,
            let topController = navController.topViewController {
            // eg: mkaddtohomescreen://page/view1
            // url.host = page
            // url.path = /view1
            if url.absoluteString.hasPrefix("mkaddtohomescreen://") {
                // 说明是APP的URL Scheme，处理
                
                let targetVC = targetViewController(from: url.path)
                if targetVC != nil {
                    // 判断当前显示的界面是否是要跳转的界面
                    if topController.classForCoder == targetVC?.classForCoder {
                        return true
                    }
                    
                    navController.pushViewController(targetVC!, animated: true)
                }
                else {
                    return true
                }
            }
        }
        return true
    }

    // 根据URL path返回要跳转的界面
    func targetViewController(from path: String) -> UIViewController? {
        var targetVC: UIViewController?
        switch path {
        // 根据URL的path跳转不同路径
        case "/view1":
            targetVC = Method1ViewController()
            break
        case "/view2":
            targetVC = Method2ViewController()
            break
        case "/view3":
            targetVC = Method3ViewController()
            break
        default:
            targetVC = nil
            break
        }
        return targetVC
    }

```


**第二步** H5参考[47.给App的某个功能添加快捷方式](https://github.com/DarielChen/iOSTips/tree/master/Demo/47.%E7%BB%99App%E7%9A%84%E6%9F%90%E4%B8%AA%E5%8A%9F%E8%83%BD%E6%B7%BB%E5%8A%A0%E5%BF%AB%E6%8D%B7%E6%96%B9%E5%BC%8F)
中的shortcuts.html，其中共有三部分，大致为：

- header部分定义了网页的标题，以及显示到桌面快捷方式的图标和标题
- body部分则定义来这个网页的内容，其实是引导用户如何添加到桌面
- script部分则是做了一个判断，判断是桌面快捷方式进入的情况，自己调用redirect


代码如下：

``` HTML

<!DOCTYPE html>
<html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="#ffffff">
        <meta name="apple-mobile-web-app-title" content="\(title)">
            
        <link rel="apple-touch-icon-precomposed" href="data:image/jpeg;base64,\(feature_icon)"/>
        <title>\(title)</title>
        
    </head>
    <script>document.documentElement.style.fontSize = 100 * document.documentElement.clientWidth / 375 + "px"</script>
    <style>
        
        * { margin: 0; padding: 0 }
        body, html { height: 100%; width: 100%; overflow: hidden; background: #f3f2f2; text-align: center }
        .main { color: #333; text-align: center }
        .subject { margin-top: 1rem; font-size: .2rem }
        .guide { width: 100%; position: absolute; left: 0; bottom: .3rem }
        .guide .content { position: relative; z-index: 20; width: 3.5rem; padding-top: .16rem; padding-bottom: .06rem; margin: 0 auto; border-radius: .04rem; box-shadow: 0 6px 15px rgba(0, 0, 0, .13); background: #fff; font-size: .14rem }
        .guide .tips { position: relative; z-index: 20 }
        .guide .icon { width: .2rem; height: .24rem; margin: 0 .035rem .02rem; vertical-align: bottom }
        .guide .toolbar { width: 100%; height: auto; margin-top: -.12rem; position: relative; z-index: 10 }
        .guide .arrow { width: .27rem; height: auto; position: absolute; left: 50%; bottom: -.26rem; margin-left: -.135rem; z-index: 10 }
    
    </style>
    <body>
        <a id="redirect" href="\(urlToRedirect.absoluteString)"></a>
        <div id="container">
            <div class="main">
                <div class="subject">添加快捷功能到桌面</div>
            </div>
            <div class="guide">
                <div class="content">
                    <p class="tips">
                    点击下方工具栏上的<img class="icon" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/XEbFrgamEdvSxVFOBeuZ.png">
                    </p>
                    <p class="tips">
                        并选择<img class="icon" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/IkKEhyTLQpYtqXMZBYtQ.png">“<strong>添加到主屏幕</strong>”
                    </p>
                    <img class="toolbar" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/oFNuXVhPJYvBDJPXJTmt.jpg">
                    <img class="arrow" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/FlBEnTRnlhMyLyVhlfZT.png">
                </div>
            </div>
        </div>
    </body>
</html>

<script type="text/javascript">
    
    if (window.navigator.standalone) {
        
        var element = document.getElementById('container');
        element.style.display = "none";
        
        var element = document.getElementById('redirect');
        var event = document.createEvent('MouseEvents');
        event.initEvent('click', true, true, document.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
        document.body.style.backgroundColor = '#FFFFFF';
        setTimeout(function() { element.dispatchEvent(event); }, 25);
        
    } else {
        
        var element = document.getElementById('container');
        element.style.display = "inline";
    }

</script>

```

其中有关于涉及到桌面快捷方式图标和标题设置的解释可参考苹果官方的[Configuring Web Applications](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html)，如下

``` HTML

<!-- Specifying a Webpage Icon for Web Clip -->
<link rel="apple-touch-icon" href="touch-icon-iphone.png">

<!-- apple-touch-icon-precomposed与apple-touch-icon的区别为前者是原图，后者是会被苹果处理的图片，这两个的使用二选一即可
<link rel="apple-touch-icon-precomposed" href="xxx.png"> -->

<!-- Specifying a Launch Screen Image -->
<link rel="apple-touch-startup-image" href="/launch.png">

<!-- Adding a Launch Icon Title -->
<meta name="apple-mobile-web-app-title" content="AppTitle">

<!-- Hiding Safari User Interface Components -->
<meta name="apple-mobile-web-app-capable" content="yes">

<!-- Changing the Status Bar Appearance> -->
<meta name="apple-mobile-web-app-status-bar-style" content="black">

<!-- Linking to Other Native Apps -->
<a href="tel:1-408-555-5555">Call me</a>

```


### 方法一

H5提供网页，比如上面示例的代码，然后把其中header部分的内容设置为固定的

- "apple-mobile-web-app-title"是桌面快捷方式的标题
- "apple-touch-icon-precomposed"是桌面快捷方式的图片，其中的格式可以选择使用DataURI的这种样式，生成方法可以参考下面的
- "title"则是页面的标题
- \\(urlToRedirect.absoluteString)是定义好的URL Scheme链接


获取图片DataURI格式的数据Swift的代码如下

``` Swift

// 获取图片DataURI格式的数据
  if let iconData = UIImage(named: "homeScreen")?.jpegData(compressionQuality: 0.5) {
      let iconDataURI = iconData.base64EncodedString()
  }

```

具体做法：

1. 配置好客户端的URLScheme
2. H5提供编写好的网页，如果没有H5，可使用上面的shortcuts.html内容，把其中的待替换字段\\(title)、\\(feature_icon)、以及\\(urlToRedirect.absoluteString)设置为自己APP的，其中的apple-touch-icon-precomposed需要放图标经过DataURI后的String
3. 需要服务端提供URL，返回这个网页，然后客户端打开这个URL。如果服务端也没有。。。那就跟我一样，使用模拟接口返回，打开[mocky](https://designer.mocky.io/design)，(可能需要注册)，Response Content Type 设置为text/html，HTTP Response Body 中放入下面的网页内容，然后点击底部的GENERATE MY HTTP RESPONSE，就会生成一个URL

<img src="https://i.loli.net/2021/04/23/PIuayL3t28WJVOi.png" width="80%" height="80%" />

4. 最后在点击添加快捷方式的地方，直接openURL即可

``` Swift 

    func addMethod1(_ sender: Any) {
        // 方法一，不需要本地放H5数据，只需要打开指定URL即可
        // 可使用mocky来提供模拟接口
        let urlStr = "https://run.mocky.io/v3/98baaf4a-edec-4956-8506-7bbfca349d07"
        
        UIApplication.shared.open(URL(string: urlStr)!, options: [:], completionHandler: nil)
    }

```


### 方法二

可参考H5参考[47.给App的某个功能添加快捷方式](https://github.com/DarielChen/iOSTips/tree/master/Demo/47.%E7%BB%99App%E7%9A%84%E6%9F%90%E4%B8%AA%E5%8A%9F%E8%83%BD%E6%B7%BB%E5%8A%A0%E5%BF%AB%E6%8D%B7%E6%96%B9%E5%BC%8F)，使用的即是客户端自建服务器返回DataURI数据的方法，具体操作如下：

1. 配置好客户端的URL Schemes
2. 客户端使用Pod添加Swifter，用于自建服务器
3. H5提供编写好的网页，使用上面的shortcuts.html内容，其中的待替换字段不要动
4. 在点击添加快捷方式时，客户端读取html的内容并替换里面指定字段，转为DataURI，启动本地服务器，并返回DataURI数据

``` Swift

func addMethod2(_ sender: Any) {
        // 定义好的URL Scheme
        let schemeStr = "mkaddtohomescreen://page/view2"
        // 要替换的桌面快捷方式图标
        let shortcutImageData = UIImage(named: "homescreen")?.jpegData(compressionQuality: 0.5)
        // 要替换的桌面快捷方式标题
        let shortcutTitle = "添加到主屏幕2"

        guard  let schemeURL = URL(string: schemeStr),
               let shortcutImageStr = shortcutImageData?.base64EncodedString() else {
            return
        }

        // 替换H5中的内容
        let htmlStr = htmlFor(title: shortcutTitle, urlToRedirect: schemeURL.absoluteString, icon: shortcutImageStr)

        guard let base64 = htmlStr.data(using: .utf8)?.base64EncodedString() else {
            return
        }

        // 启动本地服务器，端口号是9081
        if let shortcutUrl = URL(string: "http://localhost:9081/s") {
            // 转为dataURI格式
            let server = HttpServer()
            server["/s"] = { request in
                return .movedPermanently("data:text/html;base64,\(base64)")
            }
            try? server.start(9081)
            UIApplication.shared.open(shortcutUrl, options: [:], completionHandler: nil)
        }
    }
    
    func htmlFor(title: String, urlToRedirect: String, icon: String) -> String {
        let shortcutsPath = Bundle.main.path(forResource: "content2", ofType: "html")
        
        var shortcutsContent = try! String(contentsOfFile: shortcutsPath!) as String
        shortcutsContent = shortcutsContent.replacingOccurrences(of: "\\(title)", with: title)
        shortcutsContent = shortcutsContent.replacingOccurrences(of: "\\(urlToRedirect.absoluteString)", with: urlToRedirect)
        shortcutsContent = shortcutsContent.replacingOccurrences(of: "\\(feature_icon)", with: icon)

        print(shortcutsContent)
        return shortcutsContent
    }

```

### 还没完

代码笔者放到了[Github](https://github.com/mokong/WKAddToHomeScreen)，大家可以下载运行。然后会发现，还有一个问题，使用方法一的时候，添加快捷标签到桌面后，第一次点击打开了APP，然后这个快捷标签如果没有关闭，直接从桌面再次打开，发现时白屏，并没有再次触发加载，也就没有跳转APP。而使用了DataURI加载的方法二，则没有这个问题，每次点击图标均可以直接跳转。示例如下

但是对比支付宝的添加到桌面发现支付宝的也是采用的方法一，第一次从桌面添加的快捷打开时自动跳转到支付宝，第二次点击桌面到快捷图标时，发现也是停留在一个页面，但是支付宝在这个页面上放了东西，可以称之为中间页。如下


<img src="https://i.loli.net/2021/04/23/A9QaIjZ8HN1xD7O.png" width="50%" height="50%">

要怎么实现中间页那种效果呢，目前笔者方法一的实现，点击时依赖的是服务端返回的H5网页内容，里面的Script会根据进入方式的不同，直接自跳转打开APP的URL Scheme；所以想要添加中间页，嗯，想法是：嵌套一层。即：
- 服务端返回的H5网页内容，里面的Script不直接跳转打开APP的URL Scheme，而是跳转中间页的链接
- 中间页的页面，同样的逻辑，再次跳转打开APP的URLScheme；同时中间页的页面添加按钮，点击也是跳转APP的URLScheme。
这样，第一次点击时，是桌面-中间页-APP的URL Scheme；第二次点击时，则是直接显示中间页，然后手动点击中间页上的立即进入，再次打开APP。

下面来尝试一下：
首先编辑中间页面的H5，大致内容如下，仅供参考。。。。就是把之前H5页面的body部分简单修改一下，添加一个button，事件是点击打开Scheme，同时自动跳转Scheme的逻辑也还存在。


``` HTML

<!DOCTYPE html>
<html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="#ffffff">
        <meta name="apple-mobile-web-app-title" content="方法三中间页内容">
        <title>"方法三中间页标题"</title>
        
    </head>
    <script>document.documentElement.style.fontSize = 100 * document.documentElement.clientWidth / 375 + "px"</script>
    <style>
        
        * { margin: 0; padding: 0 }
        .tips{color:#999; font-size: 30px; margin-top: 100px; text-align: center}
        .appname{color:blue; font-size: 30px; margin-top: 30px; text-align: center}
        .enter{width: 100%; height: 54px; background-color:cyan;}
    
    </style>
    <body>
        <a id="redirect" href="mkaddtohomescreen://page/view3"></a>
        <div id="B_container" class="backguide" style="display: block; width='100%'; background-color=#cyan">
          <div class="tips">你即将进入</div>
          <img id="B_icon" class="icon" src=""></img>
          <div id="B_appname" class="appname">MKAddToHomeScreen</div>
          <button class="enter" onclick="jumpSchema()" style="background-color: #red; widht=100%; height=64px">立即进入</button>
        </div>
    </body>
</html>

<script type="text/javascript">
    
    function jumpSchema() {
        var element = document.getElementById('redirect');
        var event = document.createEvent('MouseEvents');
        event.initEvent('click', true, true, document.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
        document.body.style.backgroundColor = '#FFFFFF';
        setTimeout(function() { element.dispatchEvent(event); }, 25);
    }

    
    if (window.navigator.standalone) {
        var element = document.getElementById('redirect');
        var event = document.createEvent('MouseEvents');
        event.initEvent('click', true, true, document.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
        document.body.style.backgroundColor = '#FFFFFF';
        setTimeout(function() { element.dispatchEvent(event); }, 25);
        
    } else {
        
        var element = document.getElementById('container');
        element.style.display = "inline";
    }

</script>

```

把中间页的网页放到[mocky](https://designer.mocky.io/design)中按照同样的方式(Response Content Type 设置为text/html，HTTP Response Body 中放入网页内容)，生成一个URL，然后把这个URL放到之前网页要自跳转的href中，然后再把之前网页再用[mocky](https://designer.mocky.io/design)生成一个链接，在APP中使用openURL的方式打开最后生成的这个链接，运行，调试。

发现结果是期望的，即第一次打开直接跳转，第二次打开显示中间页上面有点击跳转按钮；但是中间页的样式看起来确跟支付宝的不一样，这样生成的中间页因为经过了一次跳转，所以顶部和底部都显示了Safari二级页面的样式，嗯哼，这个不是笔者所希望的效果，而且体验支付宝的效果之后，发现支付宝的中间页是没有二级页面的那种头部和底部的，所以，那是怎么实现的呢？

<img src="https://i.loli.net/2021/04/29/2hGU6u1YcgtkApz.jpg" width="50%" height="50%">

如果不想要中间页显示为二级页面的形式，就不能采用上面那种经过一次跳转方法。只能采用单一页面的方法，在一个H5页面上想办法。所以现在想要的是，在同一个页面上，从APP跳转的时候显示“引导添加到桌面”的样式，从桌面打开时显示“中间页”的样式。

按照这个逻辑来，用两个div，包括两段样式，根据进入方式的不同，设置两个div的显示隐藏是不是就可以了呢？说做就做，把上面第二个html中的内容和样式放到第一个html中，代码如下：middle_container是中间页的div，jump_container是引导页div，然后根据window.navigator.standalone判断显示哪一个div，middle_container中按钮点击是跳转打开APP，同时再把第一个html的跳转由跳转中间页改为打开APP

Ps:
> 要检测Web应用程序当前是否运行在全屏状态，只要检测window.navigator.standalone是否为true就可以了，如果这个属性为true则表示Web应用程序当前运行在全屏状态，否则运行在非全屏状态。可用于检测到Web应用程序运行在非全屏状态时提示用户把Web应用程序的图标添加到主屏幕。



``` HTML

<!DOCTYPE html>
<html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="#ffffff">
        <meta name="apple-mobile-web-app-title" content="方法三标题">
        
        <link rel="apple-touch-icon-precomposed" href="data:image/jpeg;base64,imageData"/>
        <title>方法三网页标题</title>
        
    </head>
    <script>document.documentElement.style.fontSize = 100 * document.documentElement.clientWidth / 375 + "px"</script>
    <style>
        
        * { margin: 0; padding: 0 }
        body, html { height: 100%; width: 100%; overflow: hidden; background: #f3f2f2; text-align: center }
        .main { color: #333; text-align: center }
        .subject { margin-top: 1rem; font-size: .2rem }
        .guide { width: 100%; position: absolute; left: 0; bottom: .3rem }
        .guide .content { position: relative; z-index: 20; width: 3.5rem; padding-top: .16rem; padding-bottom: .06rem; margin: 0 auto; border-radius: .04rem; box-shadow: 0 6px 15px rgba(0, 0, 0, .13); background: #fff; font-size: .14rem }
        .guide .tips { position: relative; z-index: 20 }
        .guide .icon { width: .2rem; height: .24rem; margin: 0 .035rem .02rem; vertical-align: bottom }
        .guide .toolbar { width: 100%; height: auto; margin-top: -.12rem; position: relative; z-index: 10 }
        .guide .arrow { width: .27rem; height: auto; position: absolute; left: 50%; bottom: -.26rem; margin-left: -.135rem; z-index: 10 }
        .middle_tips{color:#999; font-size: 30px; margin-top: 100px; text-align: center}
        .middle_appname{color:blue; font-size: 30px; margin-top: 30px; text-align: center}
        .middle_enter{width: 100%; height: 54px; background-color:cyan;}
    </style>
    <body>
        <a id="redirect" href="mkaddtohomescreen://page/view3"></a>
        <div id="middle_container" class="backguide">
          <div class="middle_tips">你即将进入</div>
          <img class="middle_icon" src=""></img>
          <div class="middle_appname">MKAddToHomeScreen</div>
          <button class="middle_enter" onclick="jumpSchema()" style="background-color: #red; widht=100%; height=64px">立即进入</button>
        </div>
        <div id="jump_container">
            <div class="main">
                <div class="subject">添加快捷功能到桌面</div>
            </div>
            <div class="guide">
                <div class="content">
                    <p class="tips">
                    点击下方工具栏上的<img class="icon" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/XEbFrgamEdvSxVFOBeuZ.png">
                    </p>
                    <p class="tips">
                        并选择<img class="icon" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/IkKEhyTLQpYtqXMZBYtQ.png">“<strong>添加到主屏幕</strong>”
                    </p>
                    <img class="toolbar" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/oFNuXVhPJYvBDJPXJTmt.jpg">
                    <img class="arrow" src="https://dariel-1256714552.cos.ap-shanghai.myqcloud.com/FlBEnTRnlhMyLyVhlfZT.png">
                </div>
            </div>
        </div>
    </body>
</html>

<script type="text/javascript">
    
    function jumpSchema() {
        var element = document.getElementById('redirect');
        var event = document.createEvent('MouseEvents');
        event.initEvent('click', true, true, document.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
        document.body.style.backgroundColor = '#FFFFFF';
        setTimeout(function() { element.dispatchEvent(event); }, 25);
    }
    
    if (window.navigator.standalone) {
        
        var middle_element = document.getElementById('middle_container');
        var jump_element = document.getElementById('jump_container');
        
        middle_element.style.display = "inline";
        jump_element.style.display = "none"
        
        var element = document.getElementById('redirect');
        var event = document.createEvent('MouseEvents');
        event.initEvent('click', true, true, document.defaultView, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
        document.body.style.backgroundColor = '#FFFFFF';
        setTimeout(function() { element.dispatchEvent(event); }, 25);
        
    } else {
        
        var middle_element = document.getElementById('middle_container');
        var jump_element = document.getElementById('jump_container');
        
        middle_element.style.display = "none";
        jump_element.style.display = "inline";
    }

</script>

```

然后用当前内容放到[mocky](https://designer.mocky.io/design)生成一个链接，在程序中打开这个链接，体验，Binggo，完美。没有了二级界面的样式，而且再次打开，页面也不是空白，done。显示如下：

<img src="https://i.loli.net/2021/04/29/QRFYdJX9N2tSquj.png" width="50%" height="50%">




## 总结

笔者感觉两种方式各有优缺点：方法一依赖于网络，因为需要服务端返回的网页内容，加载完成后才能进行下一步跳转。而方法二采用DataURI方式的，把数据已经转为string放在了本地，点击时直接加载，故而不依赖网络。但方法一实现简单，客户端、H5、和服务端配合虽然有些冗余，但工作量小，很容易实现。方法二的加载采用DataURI，查看调试数据不方便。根据笔者的观察，支付宝其实采用的是方法二，没网络的时候也可以加载打开主APP，且在方法二的基础上还加上了中间页。

附图：

<img src="https://i.loli.net/2021/04/23/ACd5wtVjEFXWpqD.png" width="90%" height="90%">


## 参考
- [iOS开发 将App内部功能块生成桌面快捷方式](https://www.jianshu.com/p/9fb0824f95fe)
- [给App的某个功能添加桌面快捷方式](http://www.cocoachina.com/articles/26570)
- [ios app内页面添加到桌面](https://wayshon.com/2019/ios-app%E5%86%85%E9%A1%B5%E9%9D%A2%E6%B7%BB%E5%8A%A0%E5%88%B0%E6%A1%8C%E9%9D%A2.html)
- [ios 关于支付宝添加桌面快捷方式的探究](https://www.jianshu.com/p/2579ad49e11c)
- [模拟接口返回](https://designer.mocky.io/design)
