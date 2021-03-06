import dash
import dash_core_components as dcc
import dash_html_components as html

# Any JavaScript or CSS that is in the 'assets' folder will automatically be
# attached

# This creates the entry point to the Dash application
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
            ]),

        dcc.Graph(
            id='spectrum-graph',
            figure={
                'data': [
                    {'x': [x for x in range(1000000, 1000010)],
                     'y': [-75, -75, -60, -55, -52, -52, -55, -60, -75, -75],
                        'type': 'line', 'name': 'Signal'},
                ],
                'layout': {
                    'title': 'Spectrum',
                    'paper_bgcolor': '#000000',
                    'plot_bgcolor': '#191A1A',
                }
            },
        )
    ]
)

if __name__ == '__main__':
    app.run_server(debug=True)
