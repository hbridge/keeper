var baseFirebaseRef = new Firebase("https://keeper-dev.firebaseio.com/");


var PhotoList = React.createClass({
  mixins: [ReactFireMixin],
  getInitialState: function() {
    return {selectedRow: 0};
  },
  onRowSelected: function(index) {
    photo = this.props.items[index];
    console.log("photo selected: ");
    console.log(photo);
      
    this.props.onSelectionChange(photo); 
    this.setState({selectedRow: index});
  },
  render: function() {
      var createItem = function(item, index) {
        var isSelected = (this.state.selectedRow == index);
        return <PhotoListRow photo={ item } index= { index } onRowSelected= { this.onRowSelected } isSelected={ isSelected }/>
      }.bind(this);
      return (
        <div className="photoList">
        { this.props.items.map(createItem) }  
        </div>
      );
    },
});

var PhotoListRow = React.createClass({
  render: function() {
    var photo = this.props.photo;
        var imagePath = "https://duffy-keeper-dev.s3.amazonaws.com/" + photo.imageKey;
        var imageStyle = {
          width: 100,
          height: 100,
        };
        
        var classes = classNames({
          'row': true,
          'selected': this.props.isSelected,
        });
          
        return (<div id={ "row" + this.props.index } className={ classes } onClick={ this.handleRowSelected }>
          <div className="rowThumbnail"> <img src={ imagePath } style={ imageStyle }/></div>
          <div className="rowDetails"> { photo.category } <br /> { photo.saveDate } </div>
          <div className="clear"></div>
          
          </div>);   
    },
  handleRowSelected: function(e) {
    e.preventDefault();
    
    var row = $(e.target).closest(".row")[0];  
    var id = row.id;
    var index = id.substring(3, id.length);
    console.log("Row " + index + " with id: " + id + " tapped: " + e.target);
    this.props.onRowSelected(index);
  }
});

var PhotoView = React.createClass({
  render: function() {
    var detailViewStyle = {
      "background-repeat": "no-repeat",
      "background-size": "contain"
    }
    
    if (this.props.photo) {
      var photo = this.props.photo;
      var imagePath = "https://duffy-keeper-dev.s3.amazonaws.com/" + photo.imageKey;  
      detailViewStyle["background-image"] = "url(" + imagePath +")";
      console.log("rendering photo view with image: " + imagePath);
    }
  
    return (
      <div className="detailView">
        <div className="detailImageView" style={ detailViewStyle } ref="imageView"></div>
      </div>
    );
  },
  componentDidUpdate: function() {
    var domNode = React.findDOMNode(this.refs.imageView);
    console.log("photo view mount");
    console.log(domNode)
  },
});

var HeaderBar = React.createClass({
  render: function() {
    if (this.props.loggedIn) {
      return (
          <div className="headerBar">
            <div className="appTitle">Keeper</div> 
            <div className="signOut" onClick={ this.handleLogOut }><a href="">Sign Out</a></div>
            <div className="clear"></div>
          </div>
      );
    } else {
      return (
          <div className="headerBar">
            <div className="appTitle">Keeper</div> 
            <div className="clear"></div>
          </div>
      );
    }
  },
  
  handleLogOut: function(e) {
    baseFirebaseRef.unauth();
  },
});

var LoginView = React.createClass({
  getInitialState: function() {
    return {errorMessage:"", email:"", password:""};
  },
  render: function() {
    return (
        <div className="loginArea">
          <div className="loginAreaContent">
            <form className="loginForm" onSubmit={this.handleSubmit}>
              <input type="text" placeholder="Email" ref="email" onChange={ this.handleChange }/> <br />
              <input type="password" placeholder="Password" ref="password" onChange={ this.handleChange }/> <br />
              <a href="" className="largeButton" onClick={ this.handleSubmit }>Login</a>
            </form>
            <div id="loginErrorArea">
              <span className="errorText"> { this.state.errorMessage } </span>
            </div>
          </div>
        </div>
    );
  },
  
  handleChange: function(e) {
    e.preventDefault();
    if (e.target.type == "text") {
      this.setState({email: e.target.value});
    } else if (e.target.type == "password") {
      this.setState({password: e.target.value});
    }
  },
  
  handleSubmit: function(e) {
    e.preventDefault();
    console.log("submit pressed");
    console.log("email: " + this.state.email + " password:" + this.state.password);
    
    baseFirebaseRef.authWithPassword({
      email    : this.state.email,
      password : this.state.password,
    }, this.handleAuth);
  },
  
  handleAuth: function(error, authData) {
    if (error) {
      console.log("Login Failed!", error);
      this.setState({errorMessage: error.message});
    } else {
      console.log("Authenticated successfully with payload:", authData);
    }
  },
});

var KeeperApp = React.createClass({
  mixins: [ReactFireMixin],

  getInitialState: function() {
    return {photos: [], selectedPhoto: null, loggedIn: false};
  },

  componentWillMount: function() {
    baseFirebaseRef.onAuth(this.authDataCallback);
  },

  onSelectionChange: function(photo) {
    console.log("app selection changed, changing detail.");
    this.setState({selectedPhoto: photo});
  },
  
  authDataCallback: function (authData) {
    if (authData) {
      console.log("User " + authData.uid + " is logged in with " + authData.provider);
      this.setState({loggedIn: true}); 
      this.bindPhotosChanges();
    } else {
      console.log("User is logged out");
      this.setState({loggedIn: false});
      this.unbind("photos");
    }
  },
  
  bindPhotosChanges: function() {
    var authData = baseFirebaseRef.getAuth();
    if (!authData) {
      console.log("no auth data.");
      return;
    }
    var uid = authData.uid;
    console.log("binding photos changes for " + uid);
    var photosRef = baseFirebaseRef.child("photos");
    this.bindAsArray(
      photosRef.orderByChild("user").equalTo(uid), 
      "photos");
  },
    
  render: function() {
    if (this.state.loggedIn) {
      return (
          <div id="appDiv">
            <HeaderBar loggedIn={ true }/>
            <div id="appContent">
              <PhotoList items={ this.state.photos } onSelectionChange={ this.onSelectionChange } />
              <PhotoView photo={ this.state.selectedPhoto } />
            </div>
          </div>
      );
    } else {
      return (
        <div id="appDiv">
            <HeaderBar loggedIn={ false }/>
          <div className="appContent">
            <LoginView />
          </div>
        </div>
      );
    }
  }
});

React.render(<KeeperApp />, document.getElementById("keeper_app"));