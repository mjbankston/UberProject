import dash
import dash_core_components as dcc
import dash_html_components as html
import random
import plotly.graph_objs as go

app = dash.Dash()

app.layout = html.Div(
    className='w3-black',
    children=[
        html.Div(
            className='w3-bar w3-black',
            children=[
                html.A(
                    href='#',
                    className='w3-bar-item w3-button',
                    children='Home'
                ),
                html.A(
                    href='#',
                    className='w3-bar-item w3-button',
                    children='About'
                )
            ]
        ),

        #  dcc.Graph(
        #     id='spectrum-graph',
        #     figure={
        #         'data': [
        #             {'x': [],
        #              'y': [],
        #                 'type': 'line', 'name': 'Signal'},
        #         ],
        #         'layout': {
        #             'title': 'Spectrum',
        #             'paper_bgcolor': '#000000',
        #             'plot_bgcolor': '#191A1A',
        #         }
        #     },
        # ),

        dcc.Graph(
            id='spectrograph',
            figure={
                'data': [
                    go.Heatmap(x=[x for x in range(100, 1000, 100)],
                               y=[],
                               z=[random.randint(0, 5) for x in range(10)]
                               )
                ],
                'layout': {
                    'title': 'Spectrograph',
                    'paper_bgcolor': '#000000',
                    'plot_bgcolor': '#191A1A',
                }
            },
        )
    ]
)

if __name__ == '__main__':
    app.run_server(debug=True)
