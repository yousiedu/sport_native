import React,{Component} from 'react'
import {
    StyleSheet,
    View,
    Image,
    Text,
    TouchableHighlight,
    Dimensions,
    Platform,
    ScrollView,
    ListView,
    NativeModules,
    NativeEventEmitter
} from 'react-native'
import {
    WhiteSpace,
    WingBlank,
    Button,
    Tabs,
    List,
    Toast
} from 'antd-mobile'
import ToolBar from '../../Components/ToolBar'
import ImagePicker from 'react-native-image-crop-picker';
var QiniuModule = NativeModules.QiniuModule;
const QiniuModuleEmitter = new NativeEventEmitter(QiniuModule);

import {get,post,uploadurl,cloudStorageDomain} from '../../fetch'
const createAction = type => payload => ({type,payload})

var domain = cloudStorageDomain

import {NavigationActions} from 'react-navigation'
import {connect} from 'dva'

const defaultHeaderImage = "http://img2.woyaogexing.com/2017/09/14/d3216711f89a1fa8!400x400_big.jpg";

@connect(({appNS,user})=>({appNS,user}))
export default class Tab5Page extends Component{
    static navigationOptions = {
        tabBarLabel:'我',
        tabBarIcon: ({ focused, tintColor }) =>
            <Image
                style={[styles.icon, { tintColor: focused ? tintColor : 'gray' }]}
                source={require('../../assets/images/person.png')}
            />,
    }

    constructor(props){
        super(props);
        const ds = new ListView.DataSource({rowHasChanged:(r1,r2)=> r1 !== r2});
        this.state = {
            dataSource:ds.cloneWithRows(['John', 'Joel', 'James', 'Jimmy', 'Jackson', 'Jillian', 'Julie', 'Devin']),
        }
    }

    componentDidMount(){

    }

    componentWillUnmount(){

    }

    logout = () => {
        this.props.dispatch({type:"appNS/loginout"})
    }

    gotoDemo = () => {
        this.props.dispatch(NavigationActions.navigate({routeName:'Demo'}))
    }

    headImageUpload = async(nativepath)=>{
        var result = await QiniuModule.upload(nativepath,uploadurl);
        var url = domain + result.name;
        //Toast.info(result.name);
        var result = await post("/updateHeaderImage",{token:this.props.appNS.token,url:url})
        this.props.dispatch(createAction('user/updateHeaderImage')({headerimage:url}))
    }

    render(){
        return (
            <View style={styles.container}>
                <ToolBar
                title="我"
                navigation={this.props.navigation}
                headerRight={
                    <TouchableHighlight onPress={() => {
                        this.logout();
                    }}>
                        <Image source={require('../../assets/images/登录退出.png')} style={{width:28,height:28}}/>
                    </TouchableHighlight>
                }
                />
                <View style={Platform.OS=='ios'?styles.scrollviewIos:styles.scrollviewAndroid}>
                    <ScrollView
                    automaticallyAdjustContentInsets={false}
                    style={{flex:1}}>
                        <View style={{height:200,flexDirection:'row'}}>
                            <View style={{position:'absolute',top:0,bottom:0,left:0,right:0}}>
                                <Image source={{uri:"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1506328488925&di=2680e6cae1405560b10234ba03ecc97d&imgtype=jpg&src=http%3A%2F%2Fimg1.imgtn.bdimg.com%2Fit%2Fu%3D1684559291%2C726774350%26fm%3D214%26gp%3D0.jpg"}}
                                       style={{flex:1,resizeMode:'cover'}}
                                >
                                </Image>
                            </View>
                            <View style={{height:200,width:100,backgroundColor:'red'}}></View>
                            <View style={{flex:1,alignItems:'center'}}>
                                <TouchableHighlight onPress={()=>{
                                    //Toast.info("上传头像")
                                    ImagePicker.openPicker({
                                        //multiple: true
                                        //cropping: true
                                        compressImageQuality:0.5
                                    }).then(image => {
                                        //Toast.info(JSON.stringify(image));
                                        if(image){
                                            var nativepath = Platform.OS == 'ios'?image.path:image.path.substr(7);
                                            this.headImageUpload(nativepath,image);
                                        }
                                    });
                                }}>
                                <Image source={{uri:this.props.user.headerimage?this.props.user.headerimage:defaultHeaderImage}}
                                       style={{height:88,width:88,borderRadius:44,marginTop:20,borderWidth:2,borderColor:'white'}}
                                ></Image>
                                </TouchableHighlight>
                                <WhiteSpace/>
                                <Button size="small" type="primary">{this.props.user.nickname}</Button>
                            </View>
                            <View style={{height:200,width:100,backgroundColor:'blue'}}></View>
                        </View>
                        <List renderHeader={() => '个人'}>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {this.gotoDemo()}}>Demo</List.Item>
                            <List.Item
                            arrow="horizontal"
                            thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                            onClick={() => {}}>动态</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>任务</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>活动</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>好友</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>消息</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>成就</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>比赛</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>球队</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>训练</List.Item>
                            <List.Item
                                arrow="horizontal"
                                thumb="https://zos.alipayobjects.com/rmsportal/dNuvNrtqUztHCwM.png"
                                onClick={() => {}}>个人资料</List.Item>

                        </List>
                    </ScrollView>
                </View>
            </View>
        )
    }
}

const styles = StyleSheet.create({
    container:{
        flex:1,
        //alignItems:'center',
        //justifyContent:'center'
    },
    icon:{
        width:32,
        height:32
    },
    scrollviewIos:{
        flex:1,
        paddingBottom:49
    },
    scrollviewAndroid:{
        flex:1
    }

})