import React, { Component } from 'react';
import './index.scss';

import down from './assets/down.svg';
import caret_down from './assets/caret-down.svg';

class TCEvaluationConfusionHeaderCell extends Component {

  renderCarret = () => {
    if(this.props.enabled){
      if(this.props.direction){
        return (
          <div className="TCEvaluationConfusionHeaderCellDropDown"
               style={{"transform": "rotate(180deg)"}}>
            <img src={caret_down}/>
          </div>
        )
      }else{
        return (
          <div className="TCEvaluationConfusionHeaderCellDropDown">
            <img src={caret_down}/>
          </div>
        )
      }
    }else{
      return (
        <div className="TCEvaluationConfusionHeaderCellDropDown">
          <img src={down}/>
        </div>
      )
    }
  }

  render() {
    if(this.props.type == "images"){
      return (
        <div className="TCEvaluationConfusionHeaderCellImages">
          {this.props.name}
        </div>
      );
    }else if(this.props.type == "percent"){
      return (
        <div className="TCEvaluationConfusionHeaderCellPercent"
             onClick={this.props.onclick.bind(this)}>
          {this.props.name}
          {this.renderCarret()}
        </div>
      );
    }else if(this.props.type == "amount"){
      return (
        <div className="TCEvaluationConfusionHeaderCellAmount"
             onClick={this.props.onclick.bind(this)}>
          {this.props.name}
          {this.renderCarret()}
        </div>
      );
    }else{
      return (
        <div className="TCEvaluationConfusionHeaderCellText"
             onClick={this.props.onclick.bind(this)}>
          {this.props.name}
          {this.renderCarret()}
        </div>
      );
    }
  }
}

export default TCEvaluationConfusionHeaderCell;
