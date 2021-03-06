package com.sportdream.NativeModule;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Created by lili on 2018/4/28.
 */

public class LocalClientModuleReactPackage implements ReactPackage {
    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext){
        return Collections.emptyList();
    }

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext  reactContext){
        List<NativeModule> modules = new ArrayList<>();
        modules.add(new LocalClientModule(reactContext));
        return modules;
    }

    //@Override
    public List<Class<? extends JavaScriptModule>> createJSModules(){
        return Collections.emptyList();
    }
}
