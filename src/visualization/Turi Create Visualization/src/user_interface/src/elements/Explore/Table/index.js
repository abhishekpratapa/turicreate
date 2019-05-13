import React, { Component } from 'react';
import { StickyTable, Row, Cell } from './sticky-table'
import './index.css';

import FontAwesomeIcon from '@fortawesome/react-fontawesome'
import faAngleUp from '@fortawesome/fontawesome-free-solid/faAngleUp'
import faAngleDown from '@fortawesome/fontawesome-free-solid/faAngleDown'

var d3 = require("d3");

var numberWithCommas = d3.format(",");

class TcTable extends Component {
  constructor(props) {
    super(props)
    this.state = {
      "data": {}
    }
  }

  updateData(data) {
    this.setState({
      "data": data
    });
  }

  componentDidMount(){
    window.webkit.messageHandlers["scriptHandler"].postMessage({status: 'ready'});
  }

  render() {
    return (
      <div>
        TC Table - Start
        {JSON.stringify(this.props.table_spec)}
        {JSON.stringify(this.state.data)}
      </div>
    )
  }
}

export default TcTable;